#!/usr/bin/env python
# -*- coding: utf-8 -*-
import numpy as np
import os
from sklearn.mixture import GaussianMixture
from sklearn.metrics import accuracy_score
from sklearn.metrics import classification_report
from multiprocessing import Pool
import joblib
import time
import random

os.environ["OMP_NUM_THREADS"] = "4" # export OMP_NUM_THREADS=4
os.environ["OPENBLAS_NUM_THREADS"] = "4" # export OPENBLAS_NUM_THREADS=4 
os.environ["MKL_NUM_THREADS"] = "6" # export MKL_NUM_THREADS=6
os.environ["VECLIB_MAXIMUM_THREADS"] = "4" # export VECLIB_MAXIMUM_THREADS=4
os.environ["NUMEXPR_NUM_THREADS"] = "6" # export NUMEXPR_NUM_THREADS=6

class GMMClassifier():
  def __init__(self, featdir, modeldir) -> None:
    self.featdir = featdir
    self.modeldir = modeldir
    self.all_feats = []
    self.nclassese = 2
    self.classese_data = []
    self.all_feats_list = []
    self.test_data = []

  def _read_feat(self, feat_path):
    segment_feats = np.load(feat_path)
    return segment_feats.T

  def _multi_process_feats(self):
    feats_list = []
    pool = Pool(processes=70)
    for root, dirs, files in os.walk(self.featdir):
      for name in files:
        if ".npy" in name:
          feats_list.append([name, pool.apply_async(self._read_feat, args=(os.path.join(root, name),)).get()])
    pool.close()
    pool.join()

    self.all_feats_list = feats_list
    print("data read success")

  def _data_prep(self):
    random.seed(0)
    random.shuffle(self.all_feats_list)
    split_index = int(len(self.all_feats_list)/5)
    train_data = self.all_feats_list[split_index:]
    self.test_data = self.all_feats_list[:split_index]

    train_array = train_data[0][1]
    for i in range(1, len(train_data)):
      train_array = np.vstack((train_array, train_data[i][1]))
    
    class_list = np.unique(train_array[:,41])
    class_dict = {}
    for kind_name in class_list:
      class_dict[str(int(kind_name))] = train_array[np.where(train_array[:,41] == int(kind_name))][:,0:41]

    test_array = self.test_data[0][1]
    # print(self.test_data[0][0])
    for i in range(1, len(self.test_data)):
      test_array = np.vstack((test_array, self.test_data[i][1]))
      # print(self.test_data[i][0])

    X_test = test_array[:,0:41]
    y_test = test_array[:,41]

    prep_data = {'X_train':class_dict, 'X_test':X_test, 'y_test':y_test}
    return prep_data
  
  def _gmmtrain(self, n_components, max_iter, covariance_type, data, modelname):
    classifier = GaussianMixture(n_components=n_components, \
            max_iter=max_iter, covariance_type=covariance_type)
    classifier.fit(data)
    joblib.dump(classifier, os.path.join(self.modeldir, modelname))
    time.sleep(3)
  
  def _multi_process_gmm(self, train_data, gmmname):
    tuned_parameters = {
      'n_components':range(80,300,20),
      'max_iter':range(20,100,20),
      'covariance_type':['full'] #'spherical', 'diag', 'tied', 'full'
    }
    pool = Pool(processes=20)
    for n_components in tuned_parameters['n_components']:
      for max_iter in tuned_parameters['max_iter']:
        for covariance_type in tuned_parameters['covariance_type']:
          modelname = gmmname + "_com" + str(n_components) + "_max" + str(max_iter) + "_cov" + covariance_type + ".smn"
          pool.apply_async(self._gmmtrain, args=(n_components, max_iter, \
                      covariance_type, train_data, modelname))
    pool.close()
    pool.join()

  def _load_gmm(self, gmmname):
    classifer_list = []
    name_list = []
    for file_name in os.listdir(self.modeldir):
      if gmmname in file_name:
        gmm_path = os.path.join(self.modeldir, file_name)
        classifer_list.append(joblib.load(gmm_path))
        name_list.append(file_name)
    return classifer_list, name_list

  def _regulation(self, hyp_list):
    mid_idx = int(len(hyp_list)*2/3)
    last_cons_idx = 0
    while hyp_list[mid_idx] == 0:
      mid_idx -= 1
    for i in range(mid_idx, -1, -1):
      if hyp_list[i] == 0:
        last_cons_idx = i
        break
    for i in range(len(hyp_list)):
      if i <= last_cons_idx:
        hyp_list[i] = 0
      else:
        hyp_list[i] = 1
    return hyp_list
  
  def _seg_point(self, ref_list, hpy_list):
    ref_point = len(ref_list) - sum(ref_list)
    hpy_point = len(hpy_list) - sum(hpy_list)
    return hpy_point - ref_point

  def _test_sample(self, gmm1, gmm2):
    fp = open("test.txt", "w")
    all_ref_score = []
    all_hyp_score = []
    distance_dict = {}
    for segm_data in self.test_data:
      X_test = segm_data[1][:,0:41]
      y_test = segm_data[1][:,41]
      score1 = gmm1.score_samples(X_test)
      score2 = gmm2.score_samples(X_test)
      hyp_list = []
      for k in range(len(score1)):
        if score1[k] > score2[k]:
          hyp_list.append(0)
        else:
          hyp_list.append(1)
      
      hyp_list = self._regulation(hyp_list)
      distance = self._seg_point(y_test, hyp_list)
      if distance in distance_dict:
        distance_dict[distance] += 1
      else:
        distance_dict[distance] = 1
      all_ref_score += list(y_test)
      all_hyp_score += hyp_list

      score = accuracy_score(y_test, hyp_list)
      Accuracy = 'Accuracy:{:.3f}'.format(score)
      
      ref_str = [str(x) for x in list(y_test.astype(int))]
      hpy_str = [str(x) for x in hyp_list]
      len_con = len(list(y_test.astype(int))) - sum(list(y_test.astype(int)))
      fp.write(segm_data[0]+ " cons_len " + str(len_con) + " " +str(len_con/len(list(y_test.astype(int))))+" "+ Accuracy  + "\n")
      fp.write('\t'.join(ref_str) + "\n")
      fp.write('\t'.join(hpy_str) + "\n")
      fp.write("\n")
    score = accuracy_score(all_ref_score, all_hyp_score)
    Accuracy = 'ALL Accuracy:{:.3f}'.format(score)
    print(classification_report(all_ref_score,all_hyp_score))
    print(Accuracy)
    print(distance_dict)

  def classification(self, train_flag):
    self._multi_process_feats()
    prep_data = self._data_prep()

    consomodelname = 'gmm_NS_conso' + "_com" + str(70) + "_max" + str(60) + "_covfull.smn"
    if train_flag:
      self._multi_process_gmm(prep_data['X_train']['0'], "gmm_NS_conso")
    gmm1_list, gmm1_names = self._load_gmm(consomodelname)
    
    mvowelodelname = 'gmm_NS_vowel' + "_com" + str(70) + "_max" + str(20) + "_covfull.smn"
    if train_flag:
      self._multi_process_gmm(prep_data['X_train']['1'], "gmm_NS_vowel")
    gmm2_list, gmm2_names = self._load_gmm(mvowelodelname)

    # self._test_sample(gmm1_list[0], gmm2_list[0])
    # exit(0)
    max_score = 0
    for i in range(len(gmm1_list)):
      for j in range(len(gmm2_list)):
        score1 = gmm1_list[i].score_samples(prep_data['X_test'])
        score2 = gmm2_list[j].score_samples(prep_data['X_test'])
        phy_list = []
        for k in range(len(score1)):
          if score1[k] > score2[k]:
            phy_list.append(0)
          else:
            phy_list.append(1)
        score = accuracy_score(prep_data['y_test'], phy_list)
        max_score = max_score if max_score > score else score
        Accuracy = 'Accuracy:{:.3f}'.format(score)
        print(gmm1_names[i], gmm2_names[j], Accuracy)
    print('max_score :', max_score)
  

if __name__ == '__main__':
  featdir = "data/textgrid/"
  modeldir = "data/model/"
  GMMC = GMMClassifier(featdir, modeldir)
  GMMC.classification(False)
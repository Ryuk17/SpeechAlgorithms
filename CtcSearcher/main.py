"""
Code from https://gist.github.com/awni/56369a90d03953e370f3964c826ed4b0
Author: Awni Hannun
CTC decoder in python, 简单例子可能不太效率
用于CTC模型的输出的前缀beam search
更多细节参考
  https://distill.pub/2017/ctc/#inference
  https://arxiv.org/abs/1408.2873
"""

import numpy as np
import math
import collections

NEG_INF = -float("inf")


def make_new_beam():
    fn = lambda: (NEG_INF, NEG_INF)
    return collections.defaultdict(fn)


def logsumexp(*args):
    """
    Stable log sum exp.
    """
    if all(a == NEG_INF for a in args):
        return NEG_INF
    a_max = max(args)
    lsp = math.log(sum(math.exp(a - a_max)
                       for a in args))
    return a_max + lsp


def decode(probs, beam_size=100, blank=0):
    """
    对给定输出概率进行预测
    Arguments:
        probs: 输出概率 (e.g. post-softmax) for each
          time step. Should be an array of shape (time x output dim).
        beam_size (int): Size of the beam to use during inference.
        blank (int): Index of the CTC blank label.
    Returns the output label sequence and the corresponding negative
    log-likelihood estimated by the decoder.
    """
    T, S = probs.shape
    print("probs.shape ", probs.shape)
    probs = np.log(probs)
    print("log probs", probs)

    # 在beam中的元素为(prefix, (p_blank, p_no_blank))
    # 初始beam为空序列，第一个是前缀，第二个是后接blank的log概率，第三个是后接非blank的log概率
    # 我们需要后接blank和后接非blank两种情况，来区分重复字符是否应该被合并，对于后接blank的情况，重复字符就不会被合并
    beam = [(tuple(), (0.0, NEG_INF))]

    for t in range(T):  # 沿时间维度循环

        # 存储下一个候选集的预设置字典，每次新的时间节点都会重设
        next_beam = make_new_beam()

        for s in range(S):  # 沿词表维度循环
            p = probs[t, s]

            # p_b和p_nb分别为在当前时刻下前缀后接blank和非blank的log概率
            for prefix, (p_b, p_nb) in beam:  # 对beam进行循环

                # 如果s为blank，那么前缀不会改变
                # 因为后接的是blank，所以只需要更新前缀不变的情况下后接blank的log概率
                print(f"prefix: {prefix}, p_b: {p_b}, p_nb: {p_nb}")
                if s == blank:
                    n_p_b, n_p_nb = next_beam[prefix]
                    n_p_b = logsumexp(n_p_b, p_b + p, p_nb + p)
                    next_beam[prefix] = (n_p_b, n_p_nb)
                    continue

                # 记录前缀最后一个字符，用于判断当前字符与前缀最后一个字符是否相同
                end_t = prefix[-1] if prefix else None
                n_prefix = prefix + (s,)  # n_prefix代表next prefix

                n_p_b, n_p_nb = next_beam[n_prefix]  # n_p_b代表 next probability of blank
                # 将新的字符s加到prefix后面并将整体加入到beam中
                # 因为后接的是非blank，所以只需要更新后接非blank的log概率
                if s != end_t:
                    n_p_nb = logsumexp(n_p_nb, p_b + p, p_nb + p)
                else:
                    # 如果后接s是重复的，那么我们在更新后接非blank的log概率时，
                    # 不包括上一时刻后接非blank的概率。CTC算法会合并没有用blank分隔的重复字符
                    n_p_nb = logsumexp(n_p_nb, p_b + p)

                # 这里是加入语言模型分数的好地方
                next_beam[n_prefix] = (n_p_b, n_p_nb)

                # 这是合并的情况，如果s重复出现了，前缀也不会改变，我们也更新前缀不变的情况下后接非blank的log概率
                if s == end_t:
                    n_p_b, n_p_nb = next_beam[prefix]
                    n_p_nb = logsumexp(n_p_nb, p_nb + p)
                    next_beam[prefix] = (n_p_b, n_p_nb)

        print("next_beam ", next_beam.items())
        # 在进入下一时间步之前，排序并裁剪beam
        beam = sorted(next_beam.items(),
                      key=lambda x: logsumexp(*x[1]),
                      reverse=True)
        beam = beam[:beam_size]
        print("beam ", beam)

    best = beam[0]
    return best[0], -logsumexp(*best[1])


if __name__ == "__main__":
    np.random.seed(3)

    probs = [[0.1, 0.5, 0.4], [0.2, 0.3, 0.5], [0.5, 0.4, 0.1]]
    probs = np.array(probs)
    print("probs ", probs)

    labels, score = decode(probs, beam_size=2)
    print(labels)
    print("Score {:.3f}".format(score))

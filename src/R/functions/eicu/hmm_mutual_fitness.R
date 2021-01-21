hmm.mutual.fitness = function(hmm1, hmm2, sequence1, sequence2) {
    return(evaluation(hmm1,sequence1)+evaluation(hmm2,sequence2)-evaluation(hmm1,sequence2)-evaluation(hmm2,sequence1))
}
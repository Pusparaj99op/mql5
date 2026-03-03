//+------------------------------------------------------------------+
//|                                                   APEX_HMM.mqh   |
//|              APEX Gold Destroyer - Hidden Markov Model Engine     |
//|              Full Baum-Welch EM with corrected M-Step             |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_HMM_MQH
#define APEX_HMM_MQH

#include "APEX_Config.mqh"

//+------------------------------------------------------------------+
//| HMM Engine - Complete Baum-Welch Implementation                   |
//+------------------------------------------------------------------+
class CHMMEngine
  {
private:
   int               m_nStates;        // Number of hidden states
   int               m_window;         // Training window size
   int               m_retrainBars;    // Retrain interval
   int               m_emIterations;   // EM iterations per training

   // HMM Parameters (using native MQL5 matrix/vector types)
   matrix            m_A;              // Transition matrix [states × states]
   double            m_means[];        // Emission means [states]
   double            m_vars[];         // Emission variances [states]
   double            m_pi[];           // Initial state distribution [states]

   // Working matrices for Baum-Welch
   matrix            m_alpha;          // Forward probabilities
   matrix            m_beta;           // Backward probabilities
   matrix            m_gamma;          // State posteriors
   double            m_observations[]; // Observation sequence (log-returns)

   // State tracking
   int               m_currentState;   // Most recent Viterbi state
   double            m_stateProbs[];   // Current state probabilities
   double            m_entropy;        // Shannon entropy of state distribution
   int               m_barsSinceTrain; // Bars since last training
   bool              m_trained;        // Has been trained at least once
   string            m_symbol;

   // Internal methods
   double            GaussianPdf(double x, double mu, double var);
   void              InitializeParameters();
   bool              ForwardPass(int T);
   bool              BackwardPass(int T);
   void              ComputeGamma(int T);
   void              MStep(int T);     // FULL M-Step implementation
   int               ViterbiDecode(int T);
   double            ComputeEntropy();
   void              NormalizeRow(matrix &mat, int row, int cols);
   bool              PrepareObservations();

public:
                     CHMMEngine();
                    ~CHMMEngine();
   bool              Init(string symbol);
   void              Deinit();
   bool              Update();         // Called each new bar
   bool              ForceTrain();     // Force retrain now

   // Accessors
   ENUM_HMM_STATE    GetState()        { return (ENUM_HMM_STATE)m_currentState; }
   double            GetEntropy()      { return m_entropy; }
   double            GetStateProb(int state);
   double            GetConfidence();
   bool              IsTrained()       { return m_trained; }
   bool              IsHighEntropy()   { return m_entropy > InpEntropyThreshold; }

   // Regime fusion helper
   ENUM_APEX_REGIME  GetRegimeSuggestion();
  };

//+------------------------------------------------------------------+
CHMMEngine::CHMMEngine()
  {
   m_nStates = 3;
   m_window = 500;
   m_retrainBars = 100;
   m_emIterations = 20;
   m_currentState = 1; // Range by default
   m_entropy = 1.0;
   m_barsSinceTrain = 0;
   m_trained = false;
  }

//+------------------------------------------------------------------+
CHMMEngine::~CHMMEngine()
  {
   Deinit();
  }

//+------------------------------------------------------------------+
bool CHMMEngine::Init(string symbol)
  {
   m_symbol = symbol;
   m_nStates = InpHMM_States;
   m_window = InpHMM_Window;
   m_retrainBars = InpHMM_RetrainBars;
   m_emIterations = InpHMM_EMIterations;

   ArrayResize(m_means, m_nStates);
   ArrayResize(m_vars, m_nStates);
   ArrayResize(m_pi, m_nStates);
   ArrayResize(m_stateProbs, m_nStates);
   ArrayResize(m_observations, m_window);

   InitializeParameters();

   m_barsSinceTrain = m_retrainBars; // Force initial training
   m_trained = false;
   return true;
  }

//+------------------------------------------------------------------+
void CHMMEngine::Deinit()
  {
   m_trained = false;
  }

//+------------------------------------------------------------------+
void CHMMEngine::InitializeParameters()
  {
   // Transition matrix: high persistence on diagonal
   m_A.Init(m_nStates, m_nStates);
   for(int i = 0; i < m_nStates; i++)
     {
      for(int j = 0; j < m_nStates; j++)
        {
         if(i == j)
            m_A[i][j] = 0.8;       // 80% stay in same state
         else
            m_A[i][j] = 0.2 / (m_nStates - 1);  // Split remaining
        }
     }

   // Emission parameters: Bear(-), Range(0), Bull(+)
   m_means[0] = -0.001;   // Bear state mean log-return
   m_means[1] =  0.0;     // Range state mean log-return
   m_means[2] =  0.001;   // Bull state mean log-return

   m_vars[0] = 0.0004;    // Bear variance (high)
   m_vars[1] = 0.0001;    // Range variance (low)
   m_vars[2] = 0.0004;    // Bull variance (high)

   // Initial distribution: uniform
   for(int i = 0; i < m_nStates; i++)
      m_pi[i] = 1.0 / m_nStates;
  }

//+------------------------------------------------------------------+
//| Gaussian probability density function                             |
//+------------------------------------------------------------------+
double CHMMEngine::GaussianPdf(double x, double mu, double var)
  {
   if(var < 1e-10) var = 1e-10;  // Variance floor
   double diff = x - mu;
   double exponent = -(diff * diff) / (2.0 * var);
   double coeff = 1.0 / MathSqrt(2.0 * M_PI * var);
   double result = coeff * MathExp(exponent);
   return MathMax(result, 1e-300);  // Prevent zero
  }

//+------------------------------------------------------------------+
//| Prepare observation sequence from H1 close log-returns           |
//+------------------------------------------------------------------+
bool CHMMEngine::PrepareObservations()
  {
   double close[];
   ArraySetAsSeries(close, true);
   int copied = CopyClose(m_symbol, PERIOD_H1, 0, m_window + 2, close);
   if(copied < m_window + 2)
      return false;

   // Compute log-returns
   for(int i = 0; i < m_window; i++)
     {
      if(close[i + 1] > 0 && close[i + 2] > 0)
         m_observations[i] = MathLog(close[i + 1] / close[i + 2]);
      else
         m_observations[i] = 0;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Forward pass (alpha computation)                                  |
//+------------------------------------------------------------------+
bool CHMMEngine::ForwardPass(int T)
  {
   m_alpha.Init(T, m_nStates);

   // Initialization: alpha[0][j] = pi[j] * B(j, obs[T-1])
   // Most recent observation is at index 0, oldest at T-1
   for(int j = 0; j < m_nStates; j++)
     {
      m_alpha[0][j] = m_pi[j] * GaussianPdf(m_observations[T - 1], m_means[j], m_vars[j]);
     }

   // Normalize row 0
   NormalizeRow(m_alpha, 0, m_nStates);

   // Induction: alpha[t][j] = sum_i(alpha[t-1][i] * A[i][j]) * B(j, obs[T-1-t])
   for(int t = 1; t < T; t++)
     {
      for(int j = 0; j < m_nStates; j++)
        {
         double sum = 0;
         for(int i = 0; i < m_nStates; i++)
            sum += m_alpha[t - 1][i] * m_A[i][j];
         m_alpha[t][j] = sum * GaussianPdf(m_observations[T - 1 - t], m_means[j], m_vars[j]);
        }
      NormalizeRow(m_alpha, t, m_nStates);
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Backward pass (beta computation)                                  |
//+------------------------------------------------------------------+
bool CHMMEngine::BackwardPass(int T)
  {
   m_beta.Init(T, m_nStates);

   // Initialization: beta[T-1][j] = 1
   for(int j = 0; j < m_nStates; j++)
      m_beta[T - 1][j] = 1.0;

   // Induction backwards
   for(int t = T - 2; t >= 0; t--)
     {
      for(int i = 0; i < m_nStates; i++)
        {
         double sum = 0;
         for(int j = 0; j < m_nStates; j++)
           {
            sum += m_A[i][j] * GaussianPdf(m_observations[T - 2 - t], m_means[j], m_vars[j]) * m_beta[t + 1][j];
           }
         m_beta[t][i] = sum;
        }
      NormalizeRow(m_beta, t, m_nStates);
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Compute gamma (state posterior probabilities)                     |
//+------------------------------------------------------------------+
void CHMMEngine::ComputeGamma(int T)
  {
   m_gamma.Init(T, m_nStates);

   for(int t = 0; t < T; t++)
     {
      double sum = 0;
      for(int j = 0; j < m_nStates; j++)
        {
         m_gamma[t][j] = m_alpha[t][j] * m_beta[t][j];
         sum += m_gamma[t][j];
        }
      // Normalize
      if(sum > 0)
        {
         for(int j = 0; j < m_nStates; j++)
            m_gamma[t][j] /= sum;
        }
     }
  }

//+------------------------------------------------------------------+
//| FULL M-Step: Re-estimate A, means, variances, and pi             |
//| THIS IS THE CRITICAL FIX over the broken Advanced_HMM EA         |
//+------------------------------------------------------------------+
void CHMMEngine::MStep(int T)
  {
   // ═══════ Re-estimate Initial Distribution (pi) ═══════
   double piSum = 0;
   for(int i = 0; i < m_nStates; i++)
     {
      m_pi[i] = MathMax(m_gamma[0][i], 1e-10);
      piSum += m_pi[i];
     }
   for(int i = 0; i < m_nStates; i++)
      m_pi[i] /= piSum;

   // ═══════ Re-estimate Transition Matrix A[i][j] ═══════
   // A[i][j] = Σ_t xi(t,i,j) / Σ_t gamma(t,i)
   // xi(t,i,j) = alpha[t][i] * A[i][j] * B(j, obs[t+1]) * beta[t+1][j] / normalizer
   for(int i = 0; i < m_nStates; i++)
     {
      double gammaSum = 0;
      for(int t = 0; t < T - 1; t++)
         gammaSum += m_gamma[t][i];

      for(int j = 0; j < m_nStates; j++)
        {
         double xiSum = 0;
         for(int t = 0; t < T - 1; t++)
           {
            // Compute xi(t, i, j)
            double emission_j = GaussianPdf(m_observations[T - 2 - t], m_means[j], m_vars[j]);
            double numerator = m_alpha[t][i] * m_A[i][j] * emission_j * m_beta[t + 1][j];
            // Normalizer: sum over all i,j
            double denom = 0;
            for(int ii = 0; ii < m_nStates; ii++)
               for(int jj = 0; jj < m_nStates; jj++)
                 {
                  double em_jj = GaussianPdf(m_observations[T - 2 - t], m_means[jj], m_vars[jj]);
                  denom += m_alpha[t][ii] * m_A[ii][jj] * em_jj * m_beta[t + 1][jj];
                 }
            if(denom > 0)
               xiSum += numerator / denom;
           }

         if(gammaSum > 0)
            m_A[i][j] = MathMax(xiSum / gammaSum, 1e-10);
         else
            m_A[i][j] = 1.0 / m_nStates;
        }

      // Normalize row
      double rowSum = 0;
      for(int j = 0; j < m_nStates; j++)
         rowSum += m_A[i][j];
      if(rowSum > 0)
        {
         for(int j = 0; j < m_nStates; j++)
            m_A[i][j] /= rowSum;
        }
     }

   // ═══════ Re-estimate Emission Means ═══════
   // mu_j = Σ_t(gamma[t][j] × obs[t]) / Σ_t(gamma[t][j])
   for(int j = 0; j < m_nStates; j++)
     {
      double numSum = 0, denomSum = 0;
      for(int t = 0; t < T; t++)
        {
         double obs = m_observations[T - 1 - t];
         numSum   += m_gamma[t][j] * obs;
         denomSum += m_gamma[t][j];
        }
      if(denomSum > 0)
         m_means[j] = numSum / denomSum;
     }

   // ═══════ Re-estimate Emission Variances ═══════
   // var_j = Σ_t(gamma[t][j] × (obs[t] - mu_j)²) / Σ_t(gamma[t][j])
   for(int j = 0; j < m_nStates; j++)
     {
      double numSum = 0, denomSum = 0;
      for(int t = 0; t < T; t++)
        {
         double obs = m_observations[T - 1 - t];
         double diff = obs - m_means[j];
         numSum   += m_gamma[t][j] * diff * diff;
         denomSum += m_gamma[t][j];
        }
      if(denomSum > 0)
         m_vars[j] = MathMax(numSum / denomSum, 1e-8);  // Variance floor
      else
         m_vars[j] = 1e-4;
     }

   // ═══════ Sort States by Mean (ensure Bear < Range < Bull) ═══════
   // Simple bubble sort on means, swapping corresponding vars and pi
   for(int i = 0; i < m_nStates - 1; i++)
     {
      for(int j = i + 1; j < m_nStates; j++)
        {
         if(m_means[i] > m_means[j])
           {
            // Swap means
            double tmpMean = m_means[i]; m_means[i] = m_means[j]; m_means[j] = tmpMean;
            // Swap vars
            double tmpVar = m_vars[i]; m_vars[i] = m_vars[j]; m_vars[j] = tmpVar;
            // Swap pi
            double tmpPi = m_pi[i]; m_pi[i] = m_pi[j]; m_pi[j] = tmpPi;
            // Swap A rows and columns
            for(int k = 0; k < m_nStates; k++)
              {
               double tmpA = m_A[i][k]; m_A[i][k] = m_A[j][k]; m_A[j][k] = tmpA;
              }
            for(int k = 0; k < m_nStates; k++)
              {
               double tmpA = m_A[k][i]; m_A[k][i] = m_A[k][j]; m_A[k][j] = tmpA;
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Viterbi Algorithm - Maximum Likelihood state decoding             |
//+------------------------------------------------------------------+
int CHMMEngine::ViterbiDecode(int T)
  {
   matrix delta;
   delta.Init(T, m_nStates);
   matrix psi; // Backpointer
   psi.Init(T, m_nStates);

   // Initialization
   for(int j = 0; j < m_nStates; j++)
     {
      delta[0][j] = MathLog(MathMax(m_pi[j], 1e-300)) +
                    MathLog(MathMax(GaussianPdf(m_observations[T - 1], m_means[j], m_vars[j]), 1e-300));
      psi[0][j] = 0;
     }

   // Induction
   for(int t = 1; t < T; t++)
     {
      for(int j = 0; j < m_nStates; j++)
        {
         double maxVal = -DBL_MAX;
         int maxIdx = 0;
         for(int i = 0; i < m_nStates; i++)
           {
            double val = delta[t - 1][i] + MathLog(MathMax(m_A[i][j], 1e-300));
            if(val > maxVal)
              {
               maxVal = val;
               maxIdx = i;
              }
           }
         double emission = GaussianPdf(m_observations[T - 1 - t], m_means[j], m_vars[j]);
         delta[t][j] = maxVal + MathLog(MathMax(emission, 1e-300));
         psi[t][j] = maxIdx;
        }
     }

   // Termination: find best final state
   double maxVal = -DBL_MAX;
   int bestState = 1;
   for(int j = 0; j < m_nStates; j++)
     {
      if(delta[T - 1][j] > maxVal)
        {
         maxVal = delta[T - 1][j];
         bestState = j;
        }
     }

   // Store state probabilities from gamma at last time step
   for(int j = 0; j < m_nStates; j++)
      m_stateProbs[j] = m_gamma[T - 1][j];

   return bestState;
  }

//+------------------------------------------------------------------+
//| Normalize a row of a matrix to sum to 1                          |
//+------------------------------------------------------------------+
void CHMMEngine::NormalizeRow(matrix &mat, int row, int cols)
  {
   double sum = 0;
   for(int j = 0; j < cols; j++)
      sum += mat[row][j];
   if(sum > 0)
     {
      for(int j = 0; j < cols; j++)
         mat[row][j] /= sum;
     }
  }

//+------------------------------------------------------------------+
//| Shannon Entropy of state distribution                             |
//+------------------------------------------------------------------+
double CHMMEngine::ComputeEntropy()
  {
   double h = 0;
   double logN = MathLog(m_nStates) / MathLog(2.0);  // Max entropy
   for(int i = 0; i < m_nStates; i++)
     {
      if(m_stateProbs[i] > 1e-10)
         h -= m_stateProbs[i] * (MathLog(m_stateProbs[i]) / MathLog(2.0));
     }
   // Normalize to [0, 1]
   return (logN > 0) ? h / logN : 1.0;
  }

//+------------------------------------------------------------------+
//| Update - called each new M5 bar                                  |
//+------------------------------------------------------------------+
bool CHMMEngine::Update()
  {
   m_barsSinceTrain++;

   if(m_barsSinceTrain >= m_retrainBars)
     {
      return ForceTrain();
     }
   return m_trained;
  }

//+------------------------------------------------------------------+
//| Force Training Cycle                                              |
//+------------------------------------------------------------------+
bool CHMMEngine::ForceTrain()
  {
   // Prepare observations
   if(!PrepareObservations())
     {
      Print("APEX HMM: Failed to prepare observations");
      return false;
     }

   int T = m_window;

   // Run Baum-Welch EM algorithm
   for(int iter = 0; iter < m_emIterations; iter++)
     {
      // E-Step: Forward-Backward
      if(!ForwardPass(T)) break;
      if(!BackwardPass(T)) break;
      ComputeGamma(T);

      // M-Step: Re-estimate all parameters
      MStep(T);
     }

   // Final forward-backward for state probabilities
   ForwardPass(T);
   BackwardPass(T);
   ComputeGamma(T);

   // Viterbi decode for current state
   m_currentState = ViterbiDecode(T);

   // Compute entropy
   m_entropy = ComputeEntropy();

   m_barsSinceTrain = 0;
   m_trained = true;

   PrintFormat("APEX HMM: Trained. State=%s Entropy=%.3f Conf=%.1f%% Means=[%.5f,%.5f,%.5f]",
               (m_currentState == 0 ? "BEAR" : (m_currentState == 1 ? "RANGE" : "BULL")),
               m_entropy, GetConfidence() * 100,
               m_means[0], m_means[1], m_means[2]);

   return true;
  }

//+------------------------------------------------------------------+
double CHMMEngine::GetStateProb(int state)
  {
   if(state >= 0 && state < m_nStates)
      return m_stateProbs[state];
   return 0;
  }

//+------------------------------------------------------------------+
double CHMMEngine::GetConfidence()
  {
   if(!m_trained) return 0;
   double maxProb = 0;
   for(int i = 0; i < m_nStates; i++)
      if(m_stateProbs[i] > maxProb)
         maxProb = m_stateProbs[i];
   return maxProb;
  }

//+------------------------------------------------------------------+
//| Suggest regime based on HMM state                                 |
//+------------------------------------------------------------------+
ENUM_APEX_REGIME CHMMEngine::GetRegimeSuggestion()
  {
   if(!m_trained)
      return REGIME_RANGE;

   // High entropy = transition/uncertainty
   if(m_entropy > InpEntropyThreshold)
      return REGIME_TRANSITION;

   switch(m_currentState)
     {
      case 0:  return REGIME_BEAR;
      case 1:  return REGIME_RANGE;
      case 2:  return REGIME_BULL;
      default: return REGIME_RANGE;
     }
  }

#endif // APEX_HMM_MQH

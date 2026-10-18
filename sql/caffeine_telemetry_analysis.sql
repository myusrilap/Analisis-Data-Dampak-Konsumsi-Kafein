-- 1. ANALISIS UTAMA: Rata-rata Skor Keparahan Crash & Kecemasan Berdasarkan Sumber Kafein Utama
-- Insight: Mengetahui produk/sumber kafein mana yang paling berisiko memicu keparahan crash.
SELECT 
    primary_caffeine_source,
    COUNT(user_id) AS total_users,
    ROUND(AVG(caffeine_mg), 2) AS avg_caffeine_dosage_mg,
    ROUND(AVG(heart_rate_spike_bpm), 2) AS avg_heart_rate_spike,
    ROUND(AVG(crash_severity_score), 2) AS avg_crash_severity
FROM caffeine_crash_and_anxiety_telemetry
GROUP BY primary_caffeine_source
ORDER BY avg_crash_severity DESC;

-- 2. ANALISIS PROFIL GENETIKA: Perbandingan Waktu Onset Crash Berdasarkan Tipe Metabolizer CYP1A2
-- Insight: Membuktikan secara kuantitatif seberapa cepat "Slow Metabolizer" mengalami kelelahan dibanding "Fast Metabolizer".
SELECT 
    cyp1a2_metabolizer_type,
    COUNT(user_id) AS total_users,
    ROUND(AVG(crash_onset_hours), 2) AS avg_crash_onset_hours,
    ROUND(AVG(acute_anxiety_score), 2) AS avg_acute_anxiety_score,
    ROUND(AVG(jitters_intensity_score), 2) AS avg_jitters_intensity
FROM caffeine_crash_and_anxiety_telemetry
GROUP BY cyp1a2_metabolizer_type
ORDER BY avg_crash_onset_hours ASC;

-- 3. ANALISIS FAKTOR RISIKO: Profil Pengguna pada Kategori "Severe Crash & Tachycardia"
-- Insight: Mengidentifikasi kondisi fisik & kebiasaan (tidur, hidrasi, gula) yang memicu risiko terparah.
SELECT 
    crash_risk_level,
    COUNT(user_id) AS total_affected_users,
    ROUND(AVG(prior_sleep_hours), 2) AS avg_prior_sleep_hours,
    ROUND(AVG(daily_hydration_liters), 2) AS avg_daily_hydration_liters,
    ROUND(AVG(sugar_grams), 2) AS avg_sugar_grams,
    ROUND(AVG(caffeine_mg), 2) AS avg_caffeine_mg
FROM caffeine_crash_and_anxiety_telemetry
GROUP BY crash_risk_level
ORDER BY total_affected_users DESC;

-- 4. SEGMENTASI LANJUTAN (CTE & WINDOW FUNCTION): Klasifikasi Konsumen Berisiko Tinggi
-- Insight: Menggunakan Common Table Expression (CTE) untuk memfilter pengguna dengan dosis tinggi (>250mg) 
-- dan durasi tidur kurang dari 6 jam yang mengalami kecemasan akut di atas rata-rata.
WITH HighRiskUsers AS (
    SELECT 
        user_id,
        age,
        cyp1a2_metabolizer_type,
        caffeine_mg,
        prior_sleep_hours,
        acute_anxiety_score,
        crash_risk_level,
        ROW_NUMBER() OVER(PARTITION BY cyp1a2_metabolizer_type ORDER BY acute_anxiety_score DESC) as rank_in_metabolizer
    FROM caffeine_crash_and_anxiety_telemetry
    WHERE caffeine_mg > 250 
      AND prior_sleep_hours < 6.0
)
SELECT 
    user_id,
    age,
    cyp1a2_metabolizer_type,
    caffeine_mg,
    prior_sleep_hours,
    acute_anxiety_score,
    crash_risk_level
FROM HighRiskUsers
WHERE rank_in_metabolizer <= 5 -- Mengambil top 5 pengguna dengan kecemasan tertinggi per tipe metabolizer
ORDER BY acute_anxiety_score DESC;
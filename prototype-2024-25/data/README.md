# Measured Data — Year 1 Generation Prototype (2024–25)

`measured_results.csv` is a transcription of the physical measurements recorded in the
team's analysis script ([analysis_gravenv.py](../analysis/analysis_gravenv.py), March 2025).
These are **physical measurements** taken with a multimeter on the real prototype:

- **Setup:** barbell weights dropped ~2.5 m, driving a spool → gearbox → DC generator
- **Independent variable:** mass (10, 15, 20, 25 kg), 3 trials per mass
- **Measured:** voltage per trial (multimeter), from which average power and
  end-to-end efficiency were computed (script assumed a ~3 s effective run time)

| Mass | Avg. voltage | Avg. power | Measured efficiency |
|------|--------------|------------|---------------------|
| 10 kg | 3.13 V | 6.53 W | 18.7 % |
| 15 kg | 4.90 V | 16.0 W | 25.2 % |
| 20 kg | 6.33 V | 26.7 W | 25.6 % |
| 25 kg | 8.23 V | 45.2 W | 28.7 % |

**Provenance note:** the CSV was created in 2026 for this archive by transcribing the
arrays hard-coded in `analysis_gravenv.py`. The original raw lab notes were handwritten /
recorded during trials in winter 2024–25; if the paper originals still exist they should be
scanned into this folder. Drop height appears as 2.5 m in the analysis script, 2 m in the
first research plan, and ~2.7 m in the later logbook — the frame was rebuilt more than once,
so all three may have been true at different times. See [PROVENANCE.md](../../PROVENANCE.md).

These measurements later became the calibration anchor for the 2025–26 MATLAB simulations.

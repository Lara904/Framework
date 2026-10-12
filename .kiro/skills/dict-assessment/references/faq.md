# DICT / CIAT - FAQ

Precise answers to common questions. Cite PSA-STSSI_003 (bundled) as the authority.

**Q: What does DICT stand for? Is it the same as CIAT?**
DICT = Disponibilite/Availability, Integrite/Integrity, Confidentialite/Confidentiality,
Tracabilite/Traceability. CIAT is the same four criteria in a different letter order
(Confidentiality, Integrity, Availability, Traceability). Values are identical; only the label
order differs.

**Q: What is the scale?**
Each criterion is rated 1 (weak) to 4 (critical). See `dict-scales.md` for the per-criterion
tables.

**Q: Who decides the final value?**
The business owner (MOA), aligned with the CMDB. The assessment is a preliminary-study deliverable
and is verified during application development. An assistant/architect may PROPOSE values with
rationale, marked as "to validate with MOA/DPO".

**Q: How do I choose the Availability level?**
By the maximum tolerable duration of non-accessibility, taking existing substitution means into
account: 1 = >48h, 2 = 12-48h, 3 = 4-12h, 4 = <4h. Keep coherent with SLA and RTO/RPO
(`rto-rpo.md`).

**Q: When is Confidentiality C3 or C4?**
C3 = PSA Confidential (critical impact of disclosure; limited named/role access) - common when
personal data is present. C4 = PSA Secret (crippling impact; very restricted). For a data
initiative, C4 means automatic non-approval. VIN as the only PII -> C2.

**Q: When is Traceability 4?**
Any legal/regulatory constraint forces T=4. Also consider T=3/4 for fraud protection, financial
data, proving actions for regulators, tracking access-right changes, or when any of D/I/C = 4.

**Q: How does personal data change the rating?**
It sets a MINIMUM DICT (GDPR floor) based on the privacy risk, and the final value is
`DICT = max(standard-risk DICT, GDPR DICT)`. See `personal-data-gdpr.md`. Confirm the privacy
risk level with the DPO.

**Q: Does data that stays in the browser and is handed to another controller count?**
GDPR applicability still needs DPO confirmation. A collect-only, no-store/no-transmit component
may carry a lower processing footprint, but do not decide the GDPR floor unilaterally - propose
it as an assumption and confirm with the DPO.

**Q: What is the difference between DICT and RTO/RPO/SLA?**
DICT rates the security NEED (D/I/C/T). RTO/RPO are disaster-recovery objectives; SLA is the
expected availability. They are related (higher availability need -> tighter SLA/RTO/RPO) and are
captured together on the gate's Project Synthesis slide, but they are distinct scales
(`rto-rpo.md`).

**Q: What does the DICT drive?**
The risk-reduction measures to implement (per the PSA-DSSI_04 directive), and the security
requirements carried through the project. It is a mandatory preliminary-study deliverable.

**Q: How is it kept over time?**
It is updated as the concept evolves and systematically verified during development. This skill's
README deliverable historizes each change (see `readme-template.md`).

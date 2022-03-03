# Experiments for the GeneMark-ETP+ project

Tomas Bruna, Alexandre Lomsadze, Mark Borodovsky

Georgia Institute of Technology, Atlanta, Georgia, USA

Reference: TODO


## Overview

This repository contains documentation of experiments, data and results for
the GeneMark-ETP+ project.

### Reference annotations

To prepare the reference annotations, follow the species-specific instructions
in each species folder.

All annotation statistics were collected with the `bin/analyze_annot.py` scipt.

```bash
ls */annot/annot.gtf | xargs -P7 -I {} bash -c 'bin/analyze_annot.py {} > {}.analysis'
ls */annot/reliable.gtf | xargs -P7 -I {} bash -c 'bin/analyze_annot.py {} > {}.analysis'
```

TODO: Archive and upload annotations.

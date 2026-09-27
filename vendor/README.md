# Local libraries

- `jquery-1.8.2.min.js`: the original jQuery version, from https://code.jquery.com/jquery-1.8.2.min.js. MIT license in `jquery-LICENSE`.
- `processing-1.6.6.min.js`: Processing.js 1.6.6, from https://github.com/processing-js/processing-js/tree/v1.6.6. MIT license in `processing-LICENSE` (copied from the upstream repository).

Processing.js has one local fix: the hidden font probe uses `top: -1000px` instead of the invalid `top: -1000`, preventing a small page overflow.

Processing.js upstream SHA-256: `34b2e26ecd63419367579f6fc29fbd74cc537612807aa29b9775f3818cd0caca`.
Processing.js local SHA-256: `c88bf0abd892098d65daf26e3c5132e4e160a9b9d6141b950080609d8fecd78c`.

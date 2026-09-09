# Third-Party Notices

## Neverlose.cc UI Library

- Author: 4lpaca
- License declared by the vendored source: MIT
- Vendored path: `vendor/NeverLose.lua`

The vendored file's upstream header identifies the project as "Neverlose.cc UI Library", the author as `4lpaca`, and the license as MIT. Preserve that upstream header when updating the vendored file.

### MIT License

Copyright (c) 4lpaca

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Aftermath extraction

Visual library copied from Newz 0.6.1. The image cache directory was changed
from NLAssets to AftermathAssets. No Newz gameplay modules are included.
The repository Apache-2.0 license is preserved in LICENSE.

## sensoryESP remote integration (Aftermath 0.2.0)

- Upstream: https://github.com/rthusrtghdfhtyjkehrfh/sensoryESP
- Revision: `0e161be44ea40bbe215c82051a18258982ac47b9`
- Source: https://raw.githubusercontent.com/rthusrtghdfhtyjkehrfh/sensoryESP/0e161be44ea40bbe215c82051a18258982ac47b9/ESP.lua
- Authors listed by the upstream header: dacces, Gemini, OpenAI, Claude, Deepseek.

The renderer source is not vendored or embedded in the distribution. It is
downloaded when enabled; its fonts may also be downloaded by the upstream code.
The upstream header does not declare a license, so this notice does not assign
the repository Apache-2.0 license to the remote library. Consult the upstream
project for applicable terms. The local adapter is in `src/Integrations/SensoryESP.lua`.

from pathlib import Path

from clld.web.assets import environment

import agrobase


environment.append_path(
    Path(agrobase.__file__).parent.joinpath('static').as_posix(),
    url='/agrobase:static/')
environment.load_path = list(reversed(environment.load_path))

# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration settings, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

import os
import re

# -- Project Information -----------------------------------------------------

project = 'Upupa'
copyright = '2026-, Hadi Mottale'
author = 'Hadi Mottale'

# Dynamic version read from upupa_docs/VERSION
# Since conf.py is in upupa_docs/source/, we go up one level to reach upupa_docs/VERSION
current_dir = os.path.dirname(os.path.abspath(__file__))
version_file = os.path.abspath(os.path.join(current_dir, '..', 'VERSION'))

try:
    with open(version_file, 'r') as f:
        content = f.read().strip()
        if 'echo "' in content:
            release = content.split('"')[1]
        else:
            release = content
except Exception:
    release = '0.5.3'

version = release

# -- General Configuration ---------------------------------------------------
extensions = [
    'myst_parser',
    'sphinx_design',
    'sphinx_sitemap',
    'sphinx_rtd_theme',
    'sphinx.ext.autosectionlabel',
]

language = 'fa'
templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']
smartquotes = True

# -- HTML Output Options & Theme Options -------------------------------------
html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']
html_favicon = '_static/favicon.png'

html_css_files = [
    'custom.css',
]

html_theme_options = {
    'navigation_depth': 4,
    'collapse_navigation': False,
    'style_external_links': True,
    'vcs_pageview_mode': 'edit',
}

# -- Site Context -----------------------------------------------------------
html_baseurl = 'https://upupa.readthedocs.io/'

html_context = {
    'current_version': 'stable',
    'current_release': release,
    'versions': [('stable', '/')],
}

html_sidebars = {
    '**': ['searchbox.html', 'navigation.html']
}

# -- LaTeX Configuration for Persian ------------------------------------------
latex_engine = 'xelatex'

latex_elements = {
    'preamble': r'''
        \usepackage{bidi}
        \setmainfont{DejaVu Sans}
        \setsansfont{DejaVu Sans}
        \setmonofont{DejaVu Sans Mono}
    ''',
}

# -- Search & Markdown Optimization -------------------------------------------
myst_enable_extensions = [
    "colon_fence",
    "deflist",
]

from pathlib import Path
from io import StringIO

from lxml import etree
import pandas as pd

from PDFlib.helpers import TETDocument

defaults = {
    'page_options': {
        'granularity': 'page',
        'layouteffort': 'extra',
        'vectoranalysis': {
            'pagesizelines': True,
            'splitsequence': True
        },
        'layoutanalysis': {
            'layoutdetect': 3,
            'supertablecolumns': 2,
            'layoutrowhint': {
                'full': None,
                'separation': 'preservecolumns'
            }
        }
    },
    'doc_options': {
        'tetml': {}
    }
}

resource_dir = Path(__file__).parent / 'resources/'

"""
    Convert a dict-like object into options that are compatible with the TET command.
"""
def convert_flags(options):
    options_str = []
    for k,v in options.items():
        if isinstance(v, dict):
            options_str.append(f"{k}={{{convert_flags(v)}}}")
        elif isinstance(v, bool):
            val = "true" if v else "false"
            options_str.append(f"{k}={val}")
        elif v == None:
            options_str.append(k)
        else:
            options_str.append(f"{k}={v}")
    
    return ' '.join(options_str)

def parse_document(file, pages=None, doc_options=defaults['doc_options'], page_options=defaults['page_options']):
    doc_options = convert_flags(doc_options)
    page_options = convert_flags(page_options)
    doc = TETDocument(file, doc_options, page_options)
    doc.get_tetml(pages=pages)

    return doc

def read_bad_table(csv, sep='|', squeeze=True):
    df = pd.read_csv(StringIO(csv), sep=sep, names=range(0,100))
    if squeeze:
        df = df.dropna(how='all', axis=1)
    return df

"""
    Convert tables embedded in TETML into pandas dataframes
"""
def extract_table(tree):
    namespace = {None: 'http://www.pdflib.com/XML/TET5/TET-5.0'}
    table_transform = etree.XSLT(etree.parse(str(resource_dir / 'table.xsl')))

    tables = []
    csv = ''

    for page in tree.findall('.//Page', namespace):
        page_number = page.get('number')
        table_number = 0
        for _ in page.findall('.//Table', namespace):
            table_number += 1
            params = {'page-number': str(page_number), 'table-number': str(table_number), 'separator-char': "'|'"}

            table_csv = str(table_transform(tree, **params))
            csv += table_csv
            table = read_bad_table(table_csv, squeeze=True)
            tables.append(table)
    
    supertable = read_bad_table(csv, squeeze=False)
    return supertable, tables
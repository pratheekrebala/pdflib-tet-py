from distutils.core import setup

setup(
    name='PDFlib',
    version='5.1',
    packages=['PDFlib'],
    package_data= {'PDFlib':['bind/tetlib_py.so', 'bind/tetlib_py2.so']}
)
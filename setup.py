from distutils.core import setup
import platform
import shutil

platform_name = platform.system()

shutil.copyfile('PDFlib/bind/' + platform_name + '/tetlib_py.so', 'PDFlib/bind/tetlib_py.so')
shutil.copyfile('PDFlib/bind/' + platform_name + '/tetlib_py2.so', 'PDFlib/bind/tetlib_py2.so')

print("Building for " + platform_name)

setup(
    name='PDFlib',
    version='5.1',
    packages=['PDFlib'],
    package_data= {'PDFlib':['bind/tetlib_py.so', 'bind/tetlib_py2.so']}
)
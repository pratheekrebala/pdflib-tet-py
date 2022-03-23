from distutils.core import setup
import platform
import shutil

platform_name = platform.system()

shutil.copyfile('PDFlib/bind/' + platform_name + '/tetlib_py.so', 'PDFlib/bind/tetlib_py.so')

print("Building for " + platform_name)

setup(
    name='PDFlib',
    version='5.2',
    packages=['PDFlib'],
    include_package_data=True,
    install_requires=[
        'lxml'
    ]
)
cp libmali/libmali-bifrost-g52-g2p0-gbm.so /usr/lib/aarch64-linux-gnu/.
cd /usr/lib/aarch64-linux-gnu/
rm libMali.so
rm libEGL.so*
rm libGLES*
rm libgbm.so*
rm libmali.so*
rm libMali*
rm libOpenCL*
rm libwayland-egl*
ln -sf libmali-bifrost-g52-g2p0-gbm.so libMali.so
ln -sf libMali.so libEGL.so
ln -sf libMali.so libGLES_CM.so
ln -sf libMali.so libGLES_CM.so.1
ln -sf libMali.so libGLESv1_CM.so
ln -sf libMali.so libGLESv1_CM.so.1
ln -sf libMali.so libGLESv1_CM.so.1.1.0
ln -sf libMali.so libGLESv2.so
ln -sf libMali.so libGLESv2.so.2
ln -sf libMali.so libGLESv2.so.2.0.0
ln -sf libMali.so libGLESv2.so.2.1.0
ln -sf libMali.so libGLESv3.so
ln -sf libMali.so libGLESv3.so.3
ln -sf libMali.so libgbm.so
ln -sf libMali.so libgbm.so.1
ln -sf libMali.so libgbm.so.1.0.0
ln -sf libMali.so libmali.so
ln -sf libMali.so libmali.so.1
ln -sf libMali.so libMaliOpenCL.so
ln -sf libMali.so libOpenCL.so
ln -sf libMali.so libwayland-egl.so
ln -sf libMali.so libwayland-egl.so.1
ln -sf libMali.so libwayland-egl.so.1.0.0

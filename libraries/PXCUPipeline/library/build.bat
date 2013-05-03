@if "%PROCESSING_HOME%" == "" set PROCESSING_HOME=..\..\..\..\..\_studio\3rdparty\processing-1.5.1
if not exist "%PROCESSING_HOME%" (
	echo "Please set the PROCESSING_HOME environment variable"
) ELSE (
	if exist intel; rmdir /s /q intel
	"%JAVA_HOME%\bin\javac" -classpath "%PROCESSING_HOME%\lib\core.jar" -source 1.5 -target 1.5 -d . PXCUPipeline.java ..\..\..\..\common\pxcupipeline-jni\jsrc\*.java
	"%JAVA_HOME%\bin\jar" cf PXCUPipeline.jar intel
	REM copy /Y ..\..\..\..\common\pxcupipeline-jni\build\Win32\Release\libpxcupipeline-jni.dll libpxcupipeline-jni-Win32.dll
	REM copy /Y ..\..\..\..\common\pxcupipeline-jni\build\x64\Release\libpxcupipeline-jni.dll libpxcupipeline-jni-x64.dll
)


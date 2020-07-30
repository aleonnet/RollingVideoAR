# Flutter + Unity 3D Build

## Setup Project

```
.
├── android
├── ios
├── lib
├── test
├── unity
│   └── <Your Unity Project>
├── pubspec.yml
├── README.md
```

## Unity

1. `Build Settings` - `Switch Platform` : `Android`
2. `Build Settings` - `Texture Compression` : `GLES 3.0`
3. `Build Settings` - `Player Settings` - `Scripting Backend` : `IL2CPP`
4. `Build Settings` - `Player Settings` - `Target Architecture` : `ARMv7`, `ARM64`
5. `Flutter` - `Export Android`

위와 같이 세팅 후 상단 메뉴의 `Flutter` 를 통해 export 해주게 되면, `android` 폴더 하위에 `UnityExport` 폴더가 생성된다.

```
.
├── android
│   └── .settings
│   └── app
│   └── gradle
│   └── unity-classes
│   └── UnityExport
├── ios
├── lib
├── test
├── unity
│   └── <Your Unity Project>
├── pubspec.yml
├── README.md
```

## Android


1. 위에서 생성된 `UnityExport` 폴더가 포함되어 있는 `android` 프로젝트를 로드
```
.
├── android
│   └── .settings
│   └── app
│   └── gradle
│   └── unity-classes
│   └── UnityExport
├── ...
```


2. `UnityExport/libs` 에는 `unity-classes.jar` 를 포함한 `*.aar` 라이브러리들이 위치해 있다. 이 `aar` 파일들을 Android Module로 Import 해줘야 한다.

   `File` - `New` - `New Module` - `Import .JAR/.AAR Package` 에서 해당 `*.aar` 파일들을 선택해 import 해준다. 

```
.
├── android
│   └── .settings
│   └── app
│   └── gradle
│   └── unity-classes
│   └── UnityExport
│       └── libs
│           └── arcore_client.aar
│           └── ARPresto.aar
│           └── unity-classes.jar
│           └── UnityAds.aar
│           └── UnityAdsAndroidPlugin.aar
│           └── unityandroidpermissions.aar
│           └── UnityARCore.aar
├── ...
```

3. Import 된 모듈들은 `android` 하위 폴더로 위치시킨다. (ex, `arcore_client` 참고)

```
.
├── android
│   └── .settings
│   └── app
│   └── gradle
│   └── arcore_client
│       └── arcore_client.aar
│       └── build.gradle
│   └── unity-classes
│   └── UnityExport
│       └── libs
│           └── arcore_client.aar
│           └── ARPresto.aar
│           └── unity-classes.jar
│           └── UnityAds.aar
│           └── UnityAdsAndroidPlugin.aar
│           └── unityandroidpermissions.aar
│           └── UnityARCore.aar
├── ...
```

4. `android/settings.gradle` 에서 해당 모듈들을 include 해준다는 의미로 `include ':arcore_client'` 와 같이 추가

```gradle
include ':app', ':unity-classes', ':arcore_client', ':ARPresto', ':UnityAds', ':UnityAdsAndroidPlugin', ':unityandroidpermissions', ':UnityARCore'

def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()

def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
}

plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":$name"
    project(":$name").projectDir = pluginDirectory
}

include ":UnityExport"
project(":UnityExport").projectDir = file("./UnityExport")
```

5. `android/UnityExport/build.gradle` 에서 모듈 project들을 dependency로 추가

```gradle
dependencies {
    implementation project(':unity-classes')

    implementation project(':arcore_client')
    implementation project(':ARPresto')
    implementation project(':UnityAds')
    implementation project(':UnityAdsAndroidPlugin')
    implementation project(':unityandroidpermissions')
    implementation project(':UnityARCore')
}
```

6. Import된 모듈들은 매번 new module로 부를 필요 없이, 해당 폴더를 복사해뒀다가 다른 프로젝트에서 사용하고 gradle 설정만 맞춰주면 된다.

7. `android/UnityExport/src/main/AndroidManifest.xml` 에 activity 

```xml
 <activity android:name="com.unity3d.player.UnityPlayerActivity" android:theme="@style/UnityThemeSelector" android:screenOrientation="fullSensor" android:launchMode="singleTask" android:configChanges="mcc|mnc|locale|touchscreen|keyboard|keyboardHidden|navigation|orientation|screenLayout|uiMode|screenSize|smallestScreenSize|fontScale|layoutDirection|density" android:hardwareAccelerated="false">
    <intent-filter>
       <action android:name="android.intent.action.MAIN" />
       <category android:name="android.intent.category.LAUNCHER" />
       <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
   </intent-filter>
   <meta-data android:name="unityplayer.UnityActivity" android:value="true" />
 </activity>
```

# Which development environment to choose?

개발을 시작하기에 앞서 어떤 언어, 플랫폼을 이용해 개발을 해야할 지 정해야 한다. 충족시켜야 하는 사항은 아래와 같다.

1. Cross-Platfrom (Android, IOS)
   > Android와 IOS 를 각각 개발하기엔 개발자도 부족하고 시간도 없다. Cross Platform 되는 형태로 작업해서 개발 및 관리에 대한 리소스를 줄여야 한다. 
   > Android, IOS 모두 개발 경험이 있지만 너무 오래 전에 해봐서 Java 기반, Objective-C 기반으로만 경험해봤다. 당장 Kotlin, Swift를 공부하기엔 공부할 양이 너무 많다. 어차피 App 개발을 위해 공부를 해야한다면 모든 플랫폼을 아우를 수 있는 한가지의 언어 or 플랫폼만 공부하길 원한다.
   
2. AR 기능 지원
    > 라이브러리이나 플러그인 단에서 기본적인 AR 기능을 제공했으면 좋겠다. Floor Detection, Face Detection 등 바닥부터 개발할 시간은 없다. 적어도 요즘 기본적으로 사용하는 AR 스티커 기능 정도는 쉽게 구현이 가능한 정도로 제공되길 바란다.

## Unity

![AR Foundation](https://blogs.unity3d.com/wp-content/uploads/2018/12/image4-1.png)

처음에 생각난 것은 Unity 를 이용한 App 개발이였다. Cross Platform 도 가능하고 무엇보다 AR/VR 쪽 지원이 좋기 때문이다. [AR Foundation](https://unity.com/kr/unity/features/arfoundation)은 Google의 AR Core와 Apple의 AR Kit를 모두 지원할 수 있는 인터페이스이기 때문에 AR 기능도 Android, IOS 모두를 지원하는 형태로 개발 가능하다. Sample로 제공하고 있는  AR 프로젝트들도 많고 최근에 Unity 개발을 진행했기 때문에 Learning Curve가 낮을 것으로 판단했다. 다만 문제는 만들고자 하는 앱이 게임이 아니라 SNS 같은 서비스였기 때문에 원하는 기능들을  Unity 내에 잘 녹여낼 수 있을 지(예를 들어 갤러리에서 사진을 불러온다거나 Instagram API 연동이라던가), 확장성은 괜찮은 지에 대한 확신이 없었다(AI Framework와 함께 잘 돌아가는지). 어떻게든 가능은 할 수 있지만 App 자체 기능이 모두 Unity로 개발될 필요는 없었다. AR 부분만 Unity 로 구현되어도 충분했다. 그래서 App 의 껍데기는 Flutter로 개발되고 AR 필터를 사용해야 하는 부분만 Unity로 사용하는 방법을 생각했다.

## Unity + Flutter

이미 Flutter에 Unity가 embedding 되어 있는 plugin이 있다. ([flutter_unity_widget](https://github.com/snowballdigital/flutter-unity-view-widget)) Unity `2019.3.*` 부터 Flutter로 export 하는 기능도 지원된다. Flutter에 `AR Foundation` 샘플 앱이 embedding 되어 있는 프로젝트를 테스트 해봤다. 테스트 프로젝트는 [flutter-unity-arkit-demo](../examples/flutter-unity-arkit-demo) 에 있다.
   
개발하는 것 자체에는 문제가 없긴 한데 뭔가 아쉽다.

- 말 그대로 embedding 되어 있는 형태이다보니, AR 기능을 수행할 때 Unity App이 실행된다. (로딩시간 소요)
- Unity와 Android Studio를 번갈아가며 개발하고 빌드해야 하는데 은근 번거롭다.
- 개발하고자 하는 것이 어차피 단순히 카메라에 스티커 합성 정도의 기능인데 굳이 Unity 까지 필요할까? 기본 Native App으로도 충분히 구현할 정도의 기술인데? 틱톡이나 스노우 같은 앱도 3D 엔진까지 사용하지 않고 단순 Native App에서 AR을 구현한 것으로 보인다.

그래서 Native App 에 `AR Kit`와 `AR Core`를 한꺼번에 지원하는 오픈소스가 있으면 그것을 사용하는 방법도 좋아보인다.

## Flutter

- Google에서 개발한 Cross Platform Mobile App 개발 Framework
- `Dart` 언어
- Android, IOS 위젯을 사용하지 않고 자체 `Skia` 엔진을 이용해 UI를 직접 그린다.
- Hot Reload
- 지원 플러그인이 아직은 다양하지 않다.
- React Native에 비해 애니메이션 속도가 빠르다. React Native는 Native와 Bridge를 통해 통신하지만 Flutter는 직접 컴파일되어 Render 한다.

[arkit_plugin](https://pub.dev/packages/arkit_plugin)과 [arcore_plugin](https://pub.dev/packages/arcore_plugin)이 있긴한데 통합 인터페이스는 따로 없어보인다. 어차피 Android 부터 개발할 예정이긴 하지만 추후 IOS 개발할 때 귀찮을 수 있다. 최대한 적은 수정으로 Android, IOS 모두 지원하고 싶다!

## React Native

- Facebook에서 개발한 Open source Mobile App Framework
- `JSX`
- React Native는 Android와 IOS 컴포넌트들을 끌어다 쓰는 Bridge 역할이기 때문에, IOS와 Android 개발 각각에 맞게 디버깅 해줘야 하는 부분이 많을 수 있다.
- Hot Reload
- Flutter 보다는 느리지만 체감상 느껴지지 않을 수도
- Web으로 포팅 용이. Flutter도 지원한다고는 하지만 아직은 React 를 뛰어넘을 순 없어보임.
- 상대적으로 Community가 오래 됐고 크다.

React로 AR, VR를 개발할 수 있는 [ViroReact](https://github.com/viromedia/viro) 플랫폼이 있다. `AR Kit`, `AR Core` 모두 지원된다. 성능이나 개발 편의성이 어떤지 Sample 프로젝트 테스트 해본 후 최종 결정 할 예정이다.

# Conclusion

- Flutter는 구글이 엄청 밀어주는 프로젝트. animation, transition, camera, navigation 등의 기본적인 기능들은 다 포함하고 있지만 React Native는 외부에서 가져와서 붙여야 한다. 예를들어 navigation 같은 기능 조차도.
- Google은 Flutter를 이용해 Cross Platform 시장을 선두하길 원하지만 Facebook에게 React Native는 개발 중 사용하는 여러가지 도구 중 하나일 뿐이다. 기업이 framework를 보는 관점에서 부터 지원 수준이 얼마나 달라질 지 예상할 수 있다.
-  React Native는 Javascript를 사용한다는게 큰 장점이다. Dart라는 새로운 언어를 배울 필요가 없으니까. but, 내가 Javascript 사용하는 수준이 아주 편한 수준은 아니니 Dart를 공부해서 사용하는거나 큰 차이가 없을 것 같다.
    > Javascript, Typescript, GraphQL가 능숙하다면 React Native가 빠를거고, 그게 아니라면 flutter도 좋은 선택
- React Native는 UI 개발이 어려울 수 있겠다. 일일이 라이브러리 찾아서 붙여보고 테스트하려면. 라이브러리를 찾더라도 버그가 발생한다면 그 이슈를 해결하는데에 시간이 많이 걸릴 수 있다. 개발 속도 자체는 Flutter가 훨씬 빠를 수 있을 듯. Google에서 기본적으로 제공하는 UI만 사용해도 기본적인 것은 대부분의 Google App 정도의 UI 처럼 구현은 가능할 듯. 
- 그래도 `ViroReact` 사용해보고 제공되는 기능이 어마어마 하다면 React Native, 그게 아니라면 Flutter로 `AR Core` 붙여서 진행하는 것으로 결정

# Reference

- [Flutter vs React Native - What to Choose in 2020](https://www.thedroidsonroids.com/blog/flutter-vs-react-native-what-to-choose-in-2020)
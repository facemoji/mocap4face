# Changelog
All notable changes to this project will be documented in this file. This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.3.0 - 2022-02-18
### Changed
- Android dependency coordinates changed from `co.facemoji:mocap4face` to `alter:mocap4face`
- NPM dependency coordinates changed from `facemoji/mocap4face` to `0xalter/mocap4face`

### Fixed
- Android now supports non OES-external OpenGL textures as input
- Improved performance on Javascript

### Added
- CameraWrapper for iOS and Javascript for an easier camera access
- iOS M1 Simulator support
- Protocol-buffers-based face tracker result serialization
    - Replaces deprecated functions FaceTrackerResult.serialize() and deserializeResult()

## 0.2.0 - 2021-12-14
### Added
- Support for Web/JS
- FaceTrackerResult now contains faceRectangle representing a 2D bounding box around the detected face

### Fixed
- Fix face not detected properly when too close to camera
- Fix performance issues on Android and iOS when repeatedly querying FaceTracker.lastResult
- Fix crashes on some older Android devices

## 0.1.0 - 2021-11-02
### Initial release
- Initial release for iOS 13+ and Android. See our [blog post](https://studio.facemoji.co/docs/Introducing-mocap4face-SDK_a660c539-b3fb-4f0b-a38e-3f4e850a5769) for details about this release.


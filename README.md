# godot-google-play-billing
Godot Android plugin for the Google Play Billing library

## Differences from master branch

- Library 7.0.0 is used to adhere to Googla Play's policies about library deprecations
- Purchase dictionary includes "developer_payload" field which is required by many attribution SDKs to track IAPs

## Usage & Docs

You can find the docs for this first-party plugin in the [official Godot docs](https://docs.godotengine.org/en/stable/tutorials/platform/android_in_app_purchases.html).

You can use contents of the ``release`` folder for project integration, I update them with every commit.

## Compiling

Steps to build:

1. Clone this Git repository
2. Put `godot-lib.***.release.aar` in `./godot-google-play-billing/libs/`
3. Run `./gradlew build` in the cloned repository

If the build succeeds, you can find the resulting `.aar` files in `./godot-google-play-billing/build/outputs/aar/`.

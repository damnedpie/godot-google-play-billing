# Godot Google Billing Library 7.1.1
[![Google Billing](https://img.shields.io/badge/Google_Billing-20.1.2-gray?style=for-the-badge&logo=google%20play&logoColor=cyan&logoSize=auto&labelColor=gray&color=cyan)](https://developer.android.com/google/play/billing/integrate)
[![Godot](https://img.shields.io/badge/Godot%20Engine-3.6.2-blue?style=for-the-badge&logo=godotengine&logoSize=auto)](https://godotengine.org/)
[![Godot](https://img.shields.io/badge/Godot%20Engine-4.6.1-blue?style=for-the-badge&logo=godotengine&logoSize=auto)](https://godotengine.org/)
[![GitHub Repo stars](https://img.shields.io/github/stars/damnedpie/godot-google-play-billing?style=for-the-badge&logo=github&logoSize=auto&color=%23FFD700)](https://github.com/damnedpie/godot-google-play-billing/stargazers)

Godot Android plugin for the Google Play Billing library. Built on Godot 3.6.2 / Godot 4.6.1 dependency.

## Differences from master branch

- Purchase dictionary includes "developer_payload" field which is required by many attribution SDKs to track IAPs
- More clear and intuitive GDScript wrappers with simple API where most of the trivial work is already done for you
- Plugins and GDScript wrappers for both Godot 3 and Godot 4

## Usage & Docs

You can find the docs for this plugin in the [official Godot docs](https://docs.godotengine.org/en/stable/tutorials/platform/android_in_app_purchases.html).

You can use contents of the ``release`` folder for project integration, I update it every commit.

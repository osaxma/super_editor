**This branch adds a <u>_hacked_</u> mobile support to `super_editor`.**

The solution here is a <u>**hack**</u> one because it was written in a way where it doesn't modify any existing code but only extends upon it. For instance, all the virtual keyboard events and actions are wrapped into a fake `RawKeyEvent` to utilize the existing APIs of `super_editor` that were specifically developed for physical keyboard of desktop/web.

The main differences between this branch and the upstream/main branch are in the following files:

- [lib/src/default_editor/editor.dart](https://github.com/osaxma/super_editor/blob/mobile/super_editor/lib/src/default_editor/editor.dart) (exsiting file) where a `DefaultDocumentInteractor` was added to detect platform and select the appropriate `DocumentInteractor`. 

- [lib/src/default_editor/document_interaction_mobile.dart](https://github.com/osaxma/super_editor/blob/mobile/super_editor/lib/src/default_editor/document_interaction_mobile.dart) (new file) where all the extended code resides. 

- [example/lib/demos/demo_toolbar.dart](https://github.com/osaxma/super_editor/blob/mobile/super_editor/example/lib/demos/demo_toolbar.dart) (new file) where the following demo with a toolbar was added:

https://user-images.githubusercontent.com/46427323/116639257-c5821500-a970-11eb-8b4d-718efae5cd47.mp4

- Any other changes that are seen in `git diff` are due to the addition of `iOS` to the project. 


### Disclaimar: 

The work here is not endorsed by the `superlistapp` or `super_editor` maintainers by any means. For info about the official mobile support, please refer to the upstream repo ([#121 Add support for mobile](https://github.com/superlistapp/super_editor/issues/121)). 
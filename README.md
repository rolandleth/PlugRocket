PlugRocket is a simple app that adds Xcode's UUID to each of your plug-ins `Info.plist`'s compatibility list. This means Xcode will see them as compatible and load them, but this does not mean they are guaranteed to also work; no updates for the plug-ins are downloaded and installed. 

If a plug-in will cause Xcode to start crashing after using PlugRocket, you can use the revert function: you can either undo all the changes, or only select the plug-ins that are causing the crash.

Don't forget to also install the official updates from the plug-ins' authors when released :)

If you have any suggestions, about a feature or code improvement, I'd be more than happy to have a chat [@rolandleth](https://twitter.com/rolandleth) or at [roland@leth.ro](mailto:roland@leth.ro).
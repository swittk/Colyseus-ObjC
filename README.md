# Colyseus-ObjC
Implementation of Colyseus client using Objective C.


**This is still a work in progress, it seems to work, but more testing needs to be done**
*Please report any bugs, and pull requests are very welcome*


## Why?

Because I stumbled upon [Colyseus](http://colyseus.io) and, after fiddling with it in Unity for a while, I found that it was a library that provides one of the easiest ways to set up state synchronization and messaging, two important things for multiplayer games.

But I think normal apps should be able to use Colyseus too, and since I code mainly on iOS, and love Objective-C dearly. I decided why not try and implement a client in Objective-C?

This code is mainly based on Colyseus's Unity C# client implementation and partly on the Cocos2D C++ client (only the fossilize.h delta_apply function).


## Installation
Copy the whole Colyseus-ObjC folder into your project, import headers as you need. Main ones would be ColyseusRoom.h, ColyseusClient.h, and ColyseusMessageEventArgs.h




## TODOs
* Proper header exports (I am still pretty ignorant about framework header exports in XCode after years)
* Test some more, cleanup more code

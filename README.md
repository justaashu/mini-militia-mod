# Introduction
![Mini Militia](assets/logo.png)

Mini Militia was a very popular multiplayer game until PubG and their own commercialization killed it, It's one of the first mobile games I liked. 2 years ago, I did some modifications in the game binary and unlocked some hacks. Now that I have more free time, I wanted to finish it with as many tricks as I could find. I am going to use version 4.0.42, since newer versions have removed the LAN mode(Seriously? It was the best feature). So since it's an old version these mods will only work on LAN.

# Method
Let's start with understanding the apk file. The steps I show below are linux specific, but the general concept can be applied on Windows or MAC as well.

## Unpacking
First we unpack the [mini militia apk](https://www.androidapksbox.com/apk/doodle-army-2-mini-militia-4-0-42-242-old-apk/) file using [apktool](https://bitbucket.org/iBotPeaches/apktool/downloads/), ofcourse you need to install java for this:
```bash
$ java -jar apktool.jar d mini-militia -o unpack
I: Using Apktool 2.5.0 on mini-militia.apk
I: Loading resource table...
I: Decoding AndroidManifest.xml with resources...
I: Loading resource table from file: /home/justaashu/.local/share/apktool/framework/1.apk
I: Regular manifest package...
I: Decoding file-resources...
I: Decoding values */* XMLs...
I: Baksmaling classes.dex...
I: Baksmaling classes2.dex...
I: Copying assets and libs...
I: Copying unknown files...
I: Copying original files...
```
This will create a `unpack/` directory, with the apk file extracted. Here you can find all the code, resources and configuration files for the game.

## Important Files and Directories
Here are some important files and directories that you can poke around and find assets and configs to change.

#### AndroidManifest.xml
The android manifest file having app permissions, activities etc.

####  smali/
The smali machine code for Compiled Android Java Classes.

####  assets/presMix.mp3
The app's music track, have fun changing it with your own track.

####  assets/da2sound.ckb
The Cricket Audio Bank file that has all the game sounds.

####  fonts/
The fonts used in the app, you can modify them just to have fun.

####  sd/, hd/ and hdr/
These contain all the maps and textures configs.
`\*.tmx` are xml files having map configuration for each map. You can modify these to fiddle with weapon spwans and map data.
Multiple png files having guns, backgrounds etc.

and ... :drum: :drum:

#### lib/armeabi-v7a/libcocos2dcpp.so
The Shared Object file that contains all the machine code for Compiled C++ Classes. This is the code that handles all the gaming functions, as these will be too slow in Java.

Getting more information about the binary:
```bash
$ cd unpack/lib/armeabi-v7a
$ file libcocos2dcpp.so
libcocos2dcpp.so: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /system/bin/linker, stripped
```
We can see that it is a 32 bit ARM binary, since it is stripped, we cannot just get the information to debug the binary. We have to use a disassembler to read the machine code.

You can use any disassembler, IDA Pro would be the best for this, but if you wanna do it for free, and comfortable with terminal only applications, I recommend [Radare2](https://rada.re/n/radare2.html). It has a bit of learning curve, but once you are comfortable, its really efficient. For Windows you can use IDA Pro or any other disassembler available that supports ARM.

## Exploiting the Binary
To exploit the binary, we have to open it in radare2:
```bash
$ radare2 -a arm -b 32 libcocos2dcpp.so
Cannot determine entrypoint, using 0x0030cb40.
WARNING: No calling convention defined for this file, analysis may be inaccurate.
[0x0030cb40]> 
```

Check the symbols in the binary, since it's going to be a lot of output, we only print symbols with specific pattern:
```bash
[0x00af92c0]> is | grep -i AppPurchase
966    0x0054e8c0 0x0054e8c0 GLOBAL FUNC   180       InAppPurchaseBridge::isProductPurchased(std::string)
3984   0x0054ed30 0x0054ed30 GLOBAL FUNC   284       InAppPurchaseBridge::getProductPrice(std::string)
4026   0x0054e7e4 0x0054e7e4 GLOBAL FUNC   220       InAppPurchaseBridge::purchaseProductInGame(std::string)
7107   0x0054e978 0x0054e978 GLOBAL FUNC   12        InAppPurchaseBridge::readyToSignIn()
7108   0x0054e984 0x0054e984 GLOBAL FUNC   148       InAppPurchaseBridge::readyToPurchase()
7109   0x0054ea18 0x0054ea18 GLOBAL FUNC   128       InAppPurchaseBridge::hasPendingTransactions()
7111   0x0054ea98 0x0054ea98 GLOBAL FUNC   164       InAppPurchaseBridge::canMakePurchases()
7112   0x0054ec08 0x0054ec08 GLOBAL FUNC   296       InAppPurchaseBridge::showPurchaseStatusAlert()
7113   0x0054e794 0x0054e794 GLOBAL FUNC   18        InAppPurchaseBridge::restore()
7115   0x0054e7a8 0x0054e7a8 GLOBAL FUNC   58        InAppPurchaseBridge::purchaseProduct(std::string)
9549   0x0054e974 0x0054e974 GLOBAL FUNC   2         InAppPurchaseBridge::clearAllPurchases()
```

Now we have the names and addresses of each method. We can see the method `InAppPurchaseBridge::isProductPurchased(std::string)` at address `0x0054e8c0`. We can infer this method is responsible for pro pack purchase. Let's seek to that address and print first 100 instructions (I have cut the below output).

```bash
[0x00af92c0]> s 0x0054e8c0
[0x0054e8c0]> pd 100
            ;-- InAppPurchaseBridge::isProductPurchased(std::string):
            ;-- method.InAppPurchaseBridge.isProductPurchased_std::string:
            0x0054e8c0      10b5           push {r4, lr}               ; InAppPurchaseBridge::isProductPurchased(std::string)
            0x0054e8c2      86b0           sub sp, 0x18
            0x0054e8c4      0190           str r0, [sp, 4]
            0x0054e8c6      fbf7ddfb       bl method IapManager::sharedIapManager() ; method.IapManager.sharedIapManager
                                                                       ; IapManager::sharedIapManager()

.....

====< 0x0054e964      ffe7           b 0x54e966
     ```--> 0x0054e966      bdf332ec       blx sym.__cxa_end_cleanup
        `-> 0x0054e96a      1846           mov r0, r3
            0x0054e96c      06b0           add sp, 0x18
            0x0054e96e      10bd           pop {r4, pc}
            0x0054e970      8e44           add lr, r1
            0x0054e972      4400           lsls r4, r0, 1
            ;-- InAppPurchaseBridge::clearAllPurchases():
            ;-- method.InAppPurchaseBridge.clearAllPurchases:
            0x0054e974      7047           bx lr                       ; InAppPurchaseBridge::clearAllPurchases()
```
Towards the end we can see at `0x0054e96a` method is setting value of r3 register in r0: `mov r0, r3` with hex value `1846`. Generally r0 holds the return value of the method, so we convert this to always have value 1. We have to modify this to another 16 bit instruction as we cannot change offsets of other methods. Now, we can check different ways to set register r0 to 1 using [ARM instructions manual](https://www.keil.com/support/man/docs/armasm/armasm_dom1361289850509.htm) and see which has 16 bit instruction. You can get hex value of instructions [here](https://armconverter.com/). We will use `movs r0, 1` which has hex value `0120`.

Now we can use any hex editor, to edit the 2 bytes at address `0x0054e96a` from `1846` to `0120`. I used the `dd` command to replace the 2 bytes with our own, like below:
```bash
$ printf '\x01\x20' | dd conv=notrunc of=libcocos2dcpp.so bs=1 seek=$((0x0054e96a))
2+0 records in
2+0 records out
2 bytes copied, 2.9397e-05 s, 68.0 kB/s
```

This will make the method always return true. And we will be able to unlock the pro pack in the game. If you wanna do more modifications go ahead to the [Used Methods Section](#used-methods).

## Rebuilding the APK
Now that we have modified our binary file and other config files and assets, we need to convert it back into the apk so we can enjoy our mods.
For this just use apk tool:
```bash
$ cd ../../../
$ java -jar apktool.jar b unpack
I: Using Apktool 2.5.0
I: Checking whether sources has changed...
I: Smaling smali folder into classes.dex...
I: Checking whether sources has changed...
I: Smaling smali_classes2 folder into classes2.dex...
I: Checking whether resources has changed...
I: Building resources...
I: Copying libs... (/lib)
I: Building apk file...
I: Copying unknown files/dir...
I: Built apk...
```
This will create the new modified apk file in `unpack/dist` directory. Now we just need to sign the apk with our own key, so that it can be installed in an Android phone. Obviously, since we are signing it with our own key, we won't recieve any updates on this (which is a good thing) and it can't be installed on top of pre installed mini militia app if you have the original installed, you will have 2 instances of the app in your phone.

First we will create a key to sign our apk, this is a one time process:
```bash
$ cd unpack/dist
$ keytool -genkey -v -keystore mini.keystore -alias minikey -keyalg RSA -keysize 2048 -validity 10000
Enter keystore password:  
Re-enter new password: 
What is your first and last name?
  [Unknown]:  
What is the name of your organizational unit?
  [Unknown]:  
What is the name of your organization?
  [Unknown]:  
What is the name of your City or Locality?
  [Unknown]:  
What is the name of your State or Province?
  [Unknown]:  
What is the two-letter country code for this unit?
  [Unknown]:  
Is CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown correct?
  [no]:  yes

Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,000 days
	for: CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown
[Storing mini.keystore]
```
This will create a `mini.keystore` file with a key of alias `minikey`.

Now we simply sign our apk with the keystore:
```bash
$ jarsigner mini-militia.apk -keystore mini.keystore minikey
Enter Passphrase for keystore: 
jar signed.

Warning: 
The signer's certificate is self-signed.
```

You may also have to zipalign the apk. Only do this if previous apk doesn't work. It was not required for me. You can get the zipalign tool from android sdk. If you have android studio you can sign the apk from android studio UI as well avoiding all these steps.
```bash
zipalign -p -f -v 4 infile.apk outfile.apk
```
Now just move the apk file in your mobile phone and install it! :tada: :confetti_ball:

# Used Methods
Below are all the hacks I could figure out and the method used.

### Unlimited Ammo
Find and change instruction `subs r3, 1` to `subs r3, 0` in triggerPull method for all weapons `*::triggerPull()`. This removes the code to subtract 1 bullet at trigger pull of each weapon.

### Pro Pack
Change method `InAppPurchaseBridge::isProductPurchased(std::string)` to always return true by modifying instruction to `movs r0, 1` at address `0x0054e96a`. This sets the propack as purchased.

### Unlimited Flight
Change method `SoldierHostController::hasPower()` to always return true by modifying instruction to `movs r3, 1` at address `0x004d7f2a`. This allows us to have unlimited flight.

### No Reload
Change method `Weapon::getReloadTime()` to always return 0 by modifying instruction to `movs r0, 0` at address `0x00518358`. This sets reload time to zero for all weapons.

### Rounds Per Fire
Modify the method `Weapon::getRoundsPerFire()` to shoot 4 bullets at once by modifying instruction to `movs r0, 4` at address `0x00518666`, we can set it to any number to get one shot kill.

### Weild Dual Weapon
Modify the method `Weapon::isDualWield()` to always return true by modifying instruction `movs r0, 1` at address `0x00518696` this allows us to dual weild any weapon but it breaks the UI part as weapon goes to secondary, to resolve this we enforce weapon dual weild as primary by modifying method `Weapon::isDualWieldPrimaryOnly()` to always return true by modifying instruction to `movs r0, 1` at address `0x005186b6`.

### Fixed Spawn Weapon
Change the method `WeaponFactory::createRandomStartWeapon()` to always pass a hardcoded index to method `cocos2d::CCArray::objectAtIndex(unsigned int)` which gets the weapon for a given index at address `0x0051c454`. For this we modify instructions to set `r1` register with the hardcoded index for the weapon of our choice right before calling the `objectAtIndex` method, so we change instruction at `0x0051c452` to `movs r1, 1`.
#### Weapons and Indexes
| Index | Weapon Name |
|:-----:|:-----------:|
|0|Magnum|
|1|Uzi|
|2|Desert Eagle|

# Other Interesting Methods
You can also check other interesting methods to explore and do share other hacks that you were able to find.

* Weapon::getDamage()
* Weapon::getMeleeDamage()
* Weapon::isReloading()
* Weapon::getZoomScale()
* Weapon::changeZoomLevel()
* Weapon::setAccuracyMod(float)
* WeaponFactory::isDualWeapon(ItemType)
* WeaponFactory::createRandomSecondaryWeapon()
* WeaponFactory::createRandomPrimaryWeapon()
* SoldierHostController::getHP()
* SoldierHostController::setHP(int)
* SoldierHostController::setMaxHP(int)
* SoldierManager::getRespawnTime()
* SoldierHostController::getBackupStarterWeapon()
* SoldierHostController::getPrimaryStarterWeapon()
* InAppPurchaseBridge::getProductPrice(std::string)

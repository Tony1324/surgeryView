# Surgery View: an OpenIGTLink 3d Viewer on Apple Vision Pro 

# Overview

## Purpose
We provide a user friendly way to show and interact with 3d anatomy in an augmented reality environment through Apple Vision Pro. Surgery View aims to offer patients a more intuitive and to-scale 3d visualization of surgical operations compared as an Education Tool. This tool also allows doctors to inspect and label constructed meshes from CT and MRI results in real time.

## General Usage
Some setup is necessary to configure eye and hand tracking on Vision Pro. This can be done following [Apple Support](https://support.apple.com/guide/apple-vision-pro/turn-on-and-set-up-devd5d9e3a52/visionos) SurgeryView must be installed and can be opened from the home view.

### Front-End Application
The main interface features the controls panel, and an immersive space, where multiple models can be displayed and interacted with (referred to as a “scene”) By default, the application is preloaded with a default scene of 50 part model, but custom scenes can be loaded in real time, see OpenIGTLink Integration. 

#### Controls Panel
The window positioned to the side of the scene show a list of all 3d models, and their visibility can be toggled by selecting each item.

Below this list features a floating toolbar with various view options:

- reset: returns all objects to original size and scale
- explode: scatters each model for visibility

#### 3d-Viewer Gestures
All gestures on Vision Pro involve looking at a target using your eyes and performing either a tap or drag gesture with your hand. 

**Dragging**
Each model can be individually inspected by looking at it and pinching the index and thumb fingers, dragging it in 3d.

To move the entire scene, drag the base “plate”, a gray disk positioned at the bottom of the models.

### OpenIGTLink Integration

Surgery View acts as a client to receive messages from an appropriate OpenIGTLink server (3D Slicer running on another computer, for example). Refer to [3D Slicer Documentation](https://slicer.readthedocs.io/en/latest/user_guide/getting_started.html), and the [OpenIGTLink Protocol Description](https://github.com/openigtlink/OpenIGTLink/blob/master/Documents/Protocol/index.md) for more details. 

In short, OpenIGTLink is a set of message formats along with a network communication interface provided through the [SDKs in C/C++, Python, and Java](http://openigtlink.org/developers/). 

Surgery View currently supports the following message types:
- POLYDATA: 3d models as a mesh 
- TRANSFORM: 4x4 matrix for scale and position data

# Program Structure

Entry point is *surgeryViewApp.swift*, from here a MVVM like model is used, ModelData, which the declarative views observe for changes.
**ModelData** controls arranging views, layout functionality, and interaction with OpenIGTLink.


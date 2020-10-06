import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import com.kimmoli.camerasettings 1.0

Page
{
    id: page

    property string resolutionConfig: "/etc/camera-settings/camera-resolutions.json"

    SilicaFlickable
    {
        id: flick
        anchors.fill: parent

        contentHeight: column.height

        Column
        {
            id: column

            width: page.width

            PageHeader
            {
                //: page header
                //% "Camera settings"
                title: qsTrId("camera-settings-title")
            }

            SectionHeader
            {
                //: section header for primary camera settings
                //% "Rear camera"
                text: qsTrId("primary-camera-settings")
            }

            ComboBox
            {
                id: primary_image_resolution_combo
                //: Combobox label for image resolution
                //% "Image resolution"
                label: qsTrId("image-resolution")
                menu: ContextMenu {
                    Repeater
                    {
                        model: primary_image_resolutions_model
                        delegate: MenuItem {
                            text: resolution + " (" + aspectRatio + ")"
                            onClicked: set(primary_image_resolutions_model, index, primary_image_resolution_combo, primary_image_resolution, primary_image_viewfinder_resolution)
                        }
                    }
                }
            }
            ComboBox
            {
                id: primary_video_resolution_combo
                //: Combobox label for video resolution
                //% "Video resolution"
                label: qsTrId("video-resolution")
                menu: ContextMenu {
                    Repeater
                    {
                        model: primary_video_resolutions_model
                        delegate: MenuItem {
                            text: resolution + " (" + aspectRatio + ")"
                            onClicked: set(primary_video_resolutions_model, index, primary_video_resolution_combo, primary_video_resolution, primary_video_viewfinder_resolution)
                        }
                    }
                }
            }

            SectionHeader
            {
                //: section header for secondary camera settings
                //% "Front camera"
                text: qsTrId("secondary-camera-settings")
            }

            ComboBox
            {
                id: secondary_image_resolution_combo
                label: qsTrId("image-resolution")
                menu: ContextMenu {
                    Repeater
                    {
                        model: secondary_image_resolutions_model
                        delegate: MenuItem {
                            text: resolution + " (" + aspectRatio + ")"
                            onClicked: set(secondary_image_resolutions_model, index, secondary_image_resolution_combo, secondary_image_resolution, secondary_image_viewfinder_resolution)
                        }
                    }
                }
            }
            ComboBox
            {
                id: secondary_video_resolution_combo
                label: qsTrId("video-resolution")
                menu: ContextMenu {
                    Repeater
                    {
                        model: secondary_video_resolutions_model
                        delegate: MenuItem {
                            text: resolution + " (" + aspectRatio + ")"
                            onClicked: set(secondary_video_resolutions_model, index, secondary_video_resolution_combo, secondary_video_resolution, secondary_video_viewfinder_resolution)
                        }
                    }
                }
            }
            SectionHeader
            {
                //: section header for other settings
                //% "Other settings"
                text: qsTrId("other-settings-header")
            }
            Slider
            {
                id: video_bit_rate_slider
                width: parent.width - 2*Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                //: Slider label for video bit rate setting
                //% "Video Bitrate"
                label: qsTrId("video-bit-rate-slider-label")
                valueText: value/1000000 + " Mbps"
                minimumValue: 1000000
                maximumValue: 100000000
                stepSize: 1000000
                value: videoBitRate.value
                onReleased: if (value != videoBitRate.value) videoBitRate.value = value
            }
        }
    }    

    ConfigurationValue
    {
        id: primary_image_resolution
        key: "/apps/jolla-camera/primary/image/imageResolution"
    }
    ConfigurationValue
    {
        id: primary_image_viewfinder_resolution
        key: "/apps/jolla-camera/primary/image/viewfinderResolution"
    }
    ConfigurationValue
    {
        id: primary_video_resolution
        key: "/apps/jolla-camera/primary/video/videoResolution"
    }
    ConfigurationValue
    {
        id: primary_video_viewfinder_resolution
        key: "/apps/jolla-camera/primary/video/viewfinderResolution"
    }
    ConfigurationValue
    {
        id: secondary_image_resolution
        key: "/apps/jolla-camera/secondary/image/imageResolution"
    }
    ConfigurationValue
    {
        id: secondary_image_viewfinder_resolution
        key: "/apps/jolla-camera/secondary/image/viewfinderResolution"
    }
    ConfigurationValue
    {
        id: secondary_video_resolution
        key: "/apps/jolla-camera/secondary/video/videoResolution"
    }
    ConfigurationValue
    {
        id: secondary_video_viewfinder_resolution
        key: "/apps/jolla-camera/secondary/video/viewfinderResolution"
    }
    ConfigurationValue
    {
        id: videoBitRate
        key: "/apps/jolla-camera/videoBitRate"
        defaultValue: 12000000
        onValueChanged: video_bit_rate_slider.value = value
    }

    ListModel
    {
        id: primary_image_resolutions_model
    }

    ListModel
    {
        id: primary_video_resolutions_model
    }

    ListModel
    {
        id: secondary_image_resolutions_model
    }

    ListModel
    {
        id: secondary_video_resolutions_model
    }

    Component.onCompleted:
    {
        doesFileExist(resolutionConfig, function(o)
        {
            if(!o.responseText)
                var resolution_config = "./camera-resolutions.json";
            else
                var resolution_config = resolutionConfig;

        request(resolution_config, function(o)
        {
            var data = JSON.parse(o.responseText)

            var i
            for (i=0 ; i < data.primary.image.length ; i++)
                primary_image_resolutions_model.append({ resolution: data.primary.image[i].resolution,
                                                         viewFinder: data.primary.image[i].viewFinder,
                                                         aspectRatio: data.primary.image[i].aspectRatio })
            update(primary_image_resolutions_model, primary_image_resolution_combo, primary_image_resolution)

            for (i=0 ; i < data.primary.video.length ; i++)
                primary_video_resolutions_model.append({ resolution: data.primary.video[i].resolution,
                                                         viewFinder: data.primary.video[i].viewFinder,
                                                         aspectRatio: data.primary.video[i].aspectRatio })
            update(primary_video_resolutions_model, primary_video_resolution_combo, primary_video_resolution)

            for (i=0 ; i < data.secondary.image.length ; i++)
                secondary_image_resolutions_model.append({ resolution: data.secondary.image[i].resolution,
                                                           viewFinder: data.secondary.image[i].viewFinder,
                                                           aspectRatio: data.secondary.image[i].aspectRatio })
            update(secondary_image_resolutions_model, secondary_image_resolution_combo, secondary_image_resolution)

            for (i=0 ; i < data.secondary.video.length ; i++)
                secondary_video_resolutions_model.append({ resolution: data.secondary.video[i].resolution,
                                                           viewFinder: data.secondary.video[i].viewFinder,
                                                           aspectRatio: data.secondary.video[i].aspectRatio })
            update(secondary_video_resolutions_model, secondary_video_resolution_combo, secondary_video_resolution)
        })})
    }

    function set(model, index, combo, confval, vfconfval)
    {
        var d = model.get(index)
        confval.value = d.resolution
        vfconfval.value = d.viewFinder
        update(model, combo, confval)
    }

    function update(model, combo, confval)
    {
        //combo._updating = false
        for (var i=0 ; i<model.count; i++)
        {
            console.log("ir " + model.get(i).resolution + " cv " + confval.value)
            if (model.get(i).resolution == confval.value)
            {
                combo.currentIndex = i
                break
            }
        }
    }

    function request(url, callback)
    {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = (function(myxhr)
        {
            return function()
            {
                if(myxhr.readyState === 4) callback(myxhr);
            }
        })(xhr);
        xhr.open('GET', url, true);
        xhr.send('');
    }

    function doesFileExist(url, callback)
    {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.send('');
        xhr.onreadystatechange = (function(myxhr)
        {
            return function()
            {
                if(myxhr.readyState === 4) callback(myxhr);
            }
        })(xhr);
    }
}


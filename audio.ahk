/**
 * @source - https://www.autohotkey.com/boards/viewtopic.php?f=76&t=49980&start=20
 * http://www.daveamenta.com/2011-05/programmatically-or-command-line-change-the-default-sound-playback-device-in-windows-7/
 * https://web.archive.org/web/20190317012739/http://www.daveamenta.com/2011-05/programmatically-or-command-line-change-the-default-sound-playback-device-in-windows-7/
 */


class Audio {
    static list => this.__EnumAudioEndpoints()


    ; If you only use two audio outputs, you can just change the default values here. Otherwise, pass the names of the devices when you call the method
    static ToggleOutput(audio1, audio2) {
        try {
            device_id := this.__GetDeviceID(this.list, InStr(SoundGetName(), audio1) ? audio2 : audio1)
            this.__SetDefaultEndpoint(device_id)
            return SoundGetName()
        }
    }

    ; Very similar to the previous method but you can pass multiple outputs as an array to cycle through
    static ToggleOutputs(audioOutputs*) {
        static index := 0
        if audioOutputs.Length = 0 {
            return
        }
        index := Mod(index, audioOutputs.Length) + 1
        try this.__SetDefaultEndpoint(this.__GetDeviceID(this.list, audioOutputs[index]))
    }

    static ToggleAppVolume(appName?) {
        this.__ShiftAppVolume(0, appName?)                      ; toggle between full volume and mute
        return this
    }

    static IncreaseAppVolume(value := 5, appName?) {
        this.__ShiftAppVolume(value, appName?)    ; increase app volume with option to return with percentage sign
        return this
    }

    static DecreaseAppVolume(value := 5, appName?) {
        this.__ShiftAppVolume(-value, appName?)   ; decrease app volume with option to return with percentage sign
        return this
    }

    static GetAppVolume(appName?) {
        return this.__ShiftAppVolume(unset, appName?)                     ; return current app volume
    }

    static GetAppVolumeAsPercent(appName?) {
        value := this.__ShiftAppVolume(unset, appName?)
        return value (IsInteger(value) ? '%' : '')
    }

    ; display all audio inputs and outputs
    static GetDeviceList() {
        devices := ''
        for device in this.list {
            devices .= Format('{} ({})`n`n', device['Name'], device['ID'])
        }
        MsgBox(devices)
    }


    /*
        Generates a collection of audio endpoint devices that meet the specified criteria.
        Parameters:
            DataFlow:
                The data-flow direction for the endpoint devices in the collection.
                0   Audio rendering stream. Audio data flows from the application to the audio endpoint device, which renders the stream.
                1   Audio capture stream. Audio data flows from the audio endpoint device that captures the stream, to the application.
                2   Audio rendering or capture stream. Audio data can flow either from the application to the audio endpoint device, or from the audio endpoint device to the application.
            StateMask:
                The state or states of the endpoints that are to be included in the collection.
                1   Active. The audio adapter that connects to the endpoint device is present and enabled. In addition, if the endpoint device plugs into a jack on the adapter, then the endpoint device is plugged in.
                2   Disabled. The user has disabled the device in the Windows multimedia control panel (Mmsys.cpl).
                4   Not present. The audio adapter that connects to the endpoint device has been removed or disabled.
                8   Unplugged. The audio adapter that contains the jack for the endpoint device is present and enabled, but the endpoint device is not plugged into the jack. Only a device with jack-presence detection can be in this state.
            Return value:
                Returns an array of Map objects with the following keys:
                ID      Endpoint ID string that identifies the audio endpoint device.
                Name    The friendly name of the endpoint device.
    */
    static __EnumAudioEndpoints(dataFlow := 2, stateMask := 1) {
        list := []

        ; IMMDeviceEnumerator interface.
        ; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nn-mmdeviceapi-immdeviceenumerator
        IMMDeviceEnumerator := ComObject('{BCDE0395-E52F-467C-8E3D-C4579291692E}', '{A95664D2-9614-4F35-A746-DE8DB63617E6}')

        ; IMMDeviceEnumerator::EnumAudioEndpoints method.
        ; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-enumaudioendpoints
        ComCall(3, IMMDeviceEnumerator, 'UInt', dataFlow, 'UInt', stateMask, 'UPtrP', &IMMDeviceCollection:=0)

        ; IMMDeviceCollection::GetCount method.
        ; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevicecollection-getcount
        ComCall(3, IMMDeviceCollection, 'UIntP', &DevCount:=0)  ; Retrieves a count of the devices in the device collection.

        loop DevCount {
            list.Push(device := Map())

            ; IMMDeviceCollection::Item method.
            ; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevicecollection-item
            ComCall(4, IMMDeviceCollection, 'UInt', A_Index-1, 'UPtrP', &IMMDevice:=0)

            ; IMMDevice::GetId method.
            ; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevice-getid
            ComCall(5, IMMDevice, 'PtrP', &pBuffer:=0)
            device['ID'] := StrGet(pBuffer)
            DllCall('Ole32.dll\CoTaskMemFree', 'UPtr', pBuffer)

            ; MMDevice::OpenPropertyStore method.
            ; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevice-openpropertystore
            ComCall(4, IMMDevice, 'UInt', 0x00000000, 'UPtrP', &IPropertyStore:=0)
            device['Name'] := this.GetDeviceProp(IPropertyStore, '{A45C254E-DF1C-4EFD-8020-67D146A850E0}', 14)

            ObjRelease(IPropertyStore)
            ObjRelease(IMMDevice)
        }

        ObjRelease(IMMDeviceCollection)

        return list
    }


    /*
        Set default audio render endpoint.
        Role:
            0x1   Default Device.
            0x2   Default Communication Device.
    */
    static __SetDefaultEndpoint(deviceID, Role := 3) {
        ; Undocumented COM-interface IPolicyConfig.
        IPolicyConfig := ComObject('{870AF99C-171D-4F9E-AF0D-E63Df40c2BC9}', '{F8679F50-850A-41CF-9C72-430F290290C8}')
        if (Role & 0x1) {
            ComCall(13, IPolicyConfig, 'Str', deviceID, 'Int', 0)  ; Default Device
        }
        if (Role & 0x2) {
            ComCall(13, IPolicyConfig, 'Str', deviceID, 'Int', 2)  ; Default Communication Device
        }
        return deviceID
    }


    /*
        Device Properties (Core Audio APIs)
        https://docs.microsoft.com/en-us/windows/win32/coreaudio/device-properties

        026E516E-B814-414B-83CD-856D6FEF4822, 2   The friendly name of the audio adapter to which the endpoint device is attached.
        A45C254E-DF1C-4EFD-8020-67D146A850E0, 2   The device description of the endpoint device.
        A45C254E-DF1C-4EFD-8020-67D146A850E0,14   The friendly name of the endpoint device.
    */
    static __InitDeviceProp(clsid, n) {
        clsid := this.__CLSIDFromString(clsid, Buffer(16+4))
        NumPut('Int', n, clsid, 16)
        return clsid
    }


    static GetDeviceProp(ptr, clsid, n) {
        ; IPropertyStore::GetValue method.
        ; https://docs.microsoft.com/en-us/windows/win32/api/propsys/nf-propsys-ipropertystore-getvalue
        ComCall(5, ptr, 'Ptr', this.__InitDeviceProp(clsid, n), 'Ptr', pvar := Audio.PropVariant())
        return String(pvar)
    }


    static __GetDeviceID(list, name) {
        for device in list {
            if InStr(device['Name'], name) {
                return device['ID']
            }
        }
        throw
    }


    static __CLSIDFromString(str, buffer := 0) {
        if (!buffer) {
            buffer := buffer(16)
        }
        DllCall('Ole32\CLSIDFromString', 'Str', str, 'Ptr', buffer, 'HRESULT')
        return buffer
    }


    class PropVariant {
        __New() {
            this.buffer := Buffer(A_PtrSize == 4 ? 16 : 24)
            this.ptr    := this.buffer.ptr
            this.size   := this.buffer.size
        }

        __Delete() {
            DllCall('Ole32\PropVariantClear', 'Ptr', this.ptr, 'HRESULT')
        }

        ToString() => StrGet(NumGet(this.ptr, 8, 'UPtr'))  ; LPWSTR PROPVARIANT.pwszVal
    }


    /**
     * @author Flipeador (I think) with help from Bunker D's version
     * @source https://www.autohotkey.com/boards/viewtopic.php?t=46654
     * @param {Int} value 0-100 the value to increase or decrease the volume of a program that outputs sound
     * @param appName the window which is converted to the process name
     */

    static __ShiftAppVolume(value?, appName := WinExist('A')) {
        appName := WinGetProcessName(appName)

        IMMDeviceEnumerator := ComObject('{BCDE0395-E52F-467C-8E3D-C4579291692E}', '{A95664D2-9614-4F35-A746-DE8DB63617E6}')
        DllCall(NumGet(NumGet(IMMDeviceEnumerator.ptr, 'Ptr') + 4*A_PtrSize, 'Ptr'), 'UPtr', IMMDeviceEnumerator.Ptr, 'UInt', 0, 'UInt', 1, 'UPtrP', &IMMDevice:=0, 'UInt')

        GUID := Buffer(16)
        DllCall('Ole32.dll\CLSIDFromString', 'Str', '{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}', 'Ptr', GUID)
        DllCall(NumGet(NumGet(IMMDevice, 'Ptr') + 3*A_PtrSize, 'Ptr'), 'UPtr', IMMDevice, 'Ptr', GUID, 'UInt', 23, 'UPtr', 0, 'UPtrP', &IAudioSessionManager2:=0, 'UInt')
        ObjRelease(IMMDevice)

        DllCall(NumGet(NumGet(IAudioSessionManager2, 'Ptr') + 5*A_PtrSize, 'Ptr'), 'UPtr', IAudioSessionManager2, 'UPtrP', &IAudioSessionEnumerator:=0, 'UInt')
        ObjRelease(IAudioSessionManager2)

        DllCall(NumGet(NumGet(IAudioSessionEnumerator, 'Ptr') + 3*A_PtrSize, 'Ptr'), 'UPtr', IAudioSessionEnumerator, 'UIntP', &SessionCount:=0, 'UInt')


        loop SessionCount {
            DllCall(NumGet(NumGet(IAudioSessionEnumerator, 'Ptr') + 4*A_PtrSize, 'Ptr'), 'UPtr', IAudioSessionEnumerator, 'Int', A_Index-1, 'UPtrP', &IAudioSessionControl:=0, 'UInt')
            IAudioSessionControl2 := ComObjQuery(IAudioSessionControl, '{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}')
            ObjRelease(IAudioSessionControl)

            DllCall(NumGet(NumGet(IAudioSessionControl2.ptr, 'Ptr') + 14*A_PtrSize, 'Ptr'), 'UPtr', IAudioSessionControl2.ptr, 'UIntP', &PID:=0, 'UInt')

            PHandle := DllCall('OpenProcess', 'UInt', 0x0010|0x0400, 'Int', false, 'UInt', PID)

            if PHandle != 0 {
                name_size := 1023
                VarSetStrCapacity(&PName, name_size)

                DllCall('psapi.dll\GetModuleFileNameExW', 'UInt', PHandle, 'UInt', 0, 'Str', PName, 'UInt', name_size)
                DllCall('CloseHandle', 'Ptr', PHandle)
                SplitPath(PName, &PName)

                if (PName = appName) {
                    ISimpleAudioVolume := ComObjQuery(IAudioSessionControl2, '{87CE5498-68D6-44E5-9215-6DA47EF883D8}')
                    DllCall(NumGet(NumGet(ISimpleAudioVolume.ptr, 'Ptr') + 4*A_PtrSize, 'Ptr'), 'UPtr', ISimpleAudioVolume.ptr, 'FloatP', &PrevVolume:=0, 'UInt')

                    if not IsSet(value) {                               ; if value is not set
                        return Round(PrevVolume*100)                    ; return previous volume in a format for percentage
                    } else if value = 0 {                               ; if value is zero
                        NewVolume := PrevVolume = 1.0 ? 0.0 : 1.0       ; toggle volume
                    } else {                                            ; if value is not zero
                        NewVolume := Min(1.0, (PrevVolume + value/100)) ; set new value for volume
                    }

                    DllCall(NumGet(NumGet(ISimpleAudioVolume.ptr, 'Ptr') + 3*A_PtrSize, 'Ptr'), 'UPtr', ISimpleAudioVolume.ptr, 'Float', NewVolume , 'UPtr', 0, 'UInt')
                    ObjRelease(ISimpleAudioVolume.ptr)
                    NewVolume := Round(NewVolume*100)
                    ObjRelease(IAudioSessionControl2.ptr)
                }
            }
        }

        try return NewVolume
        catch {
            return "This app doesn't support volume."
        }
    }
}
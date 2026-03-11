#Requires AutoHotkey v2

/**
 * @author @teadrinker
 * @source https://www.autohotkey.com/boards/viewtopic.php?f=82&t=132987&sid=cafe3920f6c44b2c5fc3b828b24949ef
 */


/**
 * @example_usage
 */
; $F6:: {
;     module := RadioModule('WiFi')
;     module.SetState(module.State == 'On' ? 'Off' : 'On')
; }

class RadioModule {
    ; Docs: https://tinyurl.com/ynr9mkz4 (MSDN)
    ; Header: windows.devices.radios.h

    RadioKind         := ['Other', 'WiFi', 'MobileBroadband', 'Bluetooth', 'FM']
    RadioState        := ['Unknown', 'On', 'Off', 'Disabled']
    RadioAccessStatus := ['Unspecified', 'Allowed', 'DeniedByUser', 'DeniedBySystem']

    ; kind can be 'WiFi', 'MobileBroadband', 'Bluetooth', 'FM'
    __New(kind) {
        radios := IReadOnlyList( RadioModule.Await(IRadioStatics.GetRadiosAsync()) )
        Loop radios.Count {
            radio := IRadio(radios.Item[A_Index - 1])
        } until this.RadioKind[radio.Kind + 1] = kind && this.module := radio
        if !this.HasOwnProp('module') {
            MsgBox kind . ' not found', 'Not found', 0x30
            ExitApp
        }
        this.kind := kind
    }

    ; state can be 'On' or 'Off'
    SetState(state) {
        accessStatus := ''
        if !(state ~= 'i)^(On|Off)$') {
            MsgBox 'Only "On" and "Off" states are supported', 'State not supported', 0x30
        } else if this.State = state {
            MsgBox this.kind . ' is already turned ' . StrLower(state), ' ', 0x40
        } else {
            pIAsyncOperation := this.module.SetStateAsync(state = 'On' ? 1 : 2)
            accessStatus := this.RadioAccessStatus[RadioModule.Await(pIAsyncOperation) + 1]
            if accessStatus != 'Allowed' {
                MsgBox 'Failed to turn ' . StrLower(state) . ' ' . this.kind . '.`nAccess status: ' . accessStatus, 'Error', 0x10
            }
        }
        return accessStatus = 'Allowed'
    }

    State {
        get => this.RadioState[this.module.State + 1]
        set => this.SetState(value) ; value can be 'On' or 'Off'
    }

    Name => WrtString(this.module.Name).GetText()

    static Await(pIAsyncOperation) {
        static AsyncStatus := ['Started', 'Completed', 'Canceled', 'Error']
        AsyncOperation := IAsyncOperation(pIAsyncOperation)
        AsyncInfo := IAsyncInfo(AsyncOperation.QueryIAsyncInfo())
        Loop {
            Sleep 10
            status := AsyncStatus[AsyncInfo.Status + 1]
        } until status != 'Started'
        if (status != 'Completed') {
            throw OSError('AsyncInfo error, status: "' . status . '"', A_ThisFunc)
        }
        result := AsyncOperation.GetResults()
        AsyncInfo.Close()
        return result
    }
}

class IRadioStatics {
    static __New() {
        static IID_IRadioStatics := '{5FB6A12E-67CB-46AE-AAE9-65919F86EFF4}'
             , VT_UNKNOWN := 13, runtimeClass := 'Windows.Devices.Radios.Radio'

        DllCall('Ole32\CLSIDFromString', 'Str', IID_IRadioStatics, 'Ptr', CLSID := Buffer(16))
        this.comObj := ComValue(VT_UNKNOWN, WrtString(runtimeClass).GetFactory(CLSID))
        this.ptr := this.comObj.ptr
    }
    static GetRadiosAsync() => (ComCall(6, this, 'PtrP', &pIAsyncOperation := 0), pIAsyncOperation)
}

class IRadio extends InterfaceBase {
    SetStateAsync(state) => (ComCall(6, this, 'Int', state, 'PtrP', &pIAsyncOperation := 0), pIAsyncOperation)
    State => (ComCall( 9, this, 'IntP', &state   := 0), state)
    Name  => (ComCall(10, this, 'PtrP', &hString := 0), hString)
    Kind  => (ComCall(11, this, 'IntP', &kind    := 0), kind)
}

class IReadOnlyList extends InterfaceBase {
    Item[index] => (ComCall(6, this, 'Int', index, 'PtrP', &pItem := 0), pItem)
    Count => (ComCall(7, this, 'UIntP', &count := 0), count)
}

class IAsyncOperation extends InterfaceBase {
    QueryIAsyncInfo() => ComObjQuery(this, IID_IAsyncInfo := '{00000036-0000-0000-C000-000000000046}')
    GetResults() => (ComCall(8, this, 'PtrP', &pResult := 0), pResult)
}

class IAsyncInfo extends InterfaceBase {
    Status => (ComCall(7, this, 'PtrP', &status := 0), status)
    Close() => ComCall(10, this)
}

class InterfaceBase {
    __New(ptr) {
        this.comObj := ComValue(VT_UNKNOWN := 0xD, ptr)
        this.ptr := this.comObj.ptr
    }
}

class WrtString {
    __New(stringOrHandle) {
        if Type(stringOrHandle) = 'Integer'
            this.ptr := stringOrHandle
        else {
            DllCall('Combase\WindowsCreateString', 'Str', stringOrHandle, 'UInt', StrLen(stringOrHandle), 'PtrP', &HSTRING := 0)
            this.ptr := HSTRING
        }
    }
    __Delete() => DllCall('Combase\WindowsDeleteString', 'Ptr', this)

    GetText() => DllCall('Combase\WindowsGetStringRawBuffer', 'Ptr', this, 'Ptr', 0, 'Str')

    GetFactory(riid) {
        hr := DllCall('Combase\RoGetActivationFactory', 'Ptr', this, 'Ptr', riid, 'PtrP', &pInterface := 0)
        if (hr != 0)
            throw OSError(hr, A_ThisFunc)
        return pInterface
    }
}
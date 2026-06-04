; WIP NOT USABLE

WebSearch.Add_Engine('DeepRockGalactic', 'https://search.brave.com/search?q=deep+rock+galactic+REPLACEME&source=web', 'DRG')

WebSearch.DeepRockGalactic()
Web.DeepRockGalactic()

class Web extends WebSearch {
}

class WebSearch {
    static default_engine := this.search_engines['Google']

    static Call(input) {
        this.__Search(input)
    }

    __New(search_engine, input) {
        MsgBox(search_engine '`n' input)
    }

    static __Call(name, params) {
        retrieved_engine := this.Get_Engine(name)
        if !retrieved_engine {
            return false
        }
        WebSearch.__Search(params[1], retrieved_engine)
    }

    static __Search(input, search_engine := this.default_engine) {
        safe_url := this.Sanitize_URL(input)
        if InStr(safe_url, 'REPLACEME') {
            StrReplace(safe_url, 'REPLACEME', input)
        } else {
            url := this.search_engines[search_engine] . safe_url
        }
        Run(url)
    }

    static Get_Engine(engine_name) {
        return this.short_engines.Get(engine_name,
            this.search_engines.Get(engine_name, false)
        )
    }

    static Set_Default_Engine(search_engine) {
        this.default_engine := search_engine
    }

    static Add_Engine(name, link, short_name?) {
        this.search_engines[name] := link
        if IsSet(short_name) {
            this.short_engines[short_name] := this.search_engines[name]
        }
    }

    static search_engines := EngineRegistry(
        'Google',           'https://www.google.com/search?q=REPLACEME',
        'Brave',            'https://search.brave.com/search?q=REPLACEME&source=web',
        'DuckDuckGo',       'https://duckduckgo.com/?q=REPLACEME&t=h_&ia=web',
        'Autohotkey',       'https://search.brave.com/search?q=Autohotkey+REPLACEME&source=web',
        'Thesaurus',        'https://www.thesaurus.com/browse/REPLACEME',
        'YouTube',          'https://www.youtube.com/results?search_query=REPLACEME',
        'SubReddit',        'https://www.reddit.com/r/REPLACEME',
        'Reddit',           'https://search.brave.com/search?q=site:reddit.com+REPLACEME&source=web',
        'IMDB',             'https://www.imdb.com/find/?q=REPLACEME&ref_=nv_sr_sm',
        'Dictionary',       'https://www.dictionary.com/browse/REPLACEME',
        'Amazon',           'https://www.amazon.com/s?k=REPLACEME&crid=2YKAEPJII394M',
        ; 'Steam',            '',
    )

    static short_engines := EngineRegistry(
        'g',        this.search_engines['Google'],
        'd',        this.search_engines['DuckDuckGo'],
        't',        this.search_engines['Thesaurus'],
        'd',        this.search_engines['Dictionary'],
        'y',        this.search_engines['YouTube'],
        '/',        this.search_engines['SubReddit'],
        'red',     this.search_engines['Reddit'],
        'imdb',     this.search_engines['IMDB'],
        'am',       this.search_engines['Amazon'],
        'a',        this.search_engines['Autohotkey'],
    )

    static Sanitize_URL(url) {
        return Url_Escape(url)
        ; @source @justme https://www.autohotkey.com/boards/viewtopic.php?p=379780#p379780
        ; ======================================================================================================================
        ; UrlEscape() -> https://docs.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-urlescapea
        ; URL_DONT_ESCAPE_EXTRA_INFO     = 0x02000000
        ; URL_ESCAPE_SPACES_ONLY         = 0x04000000
        ; URL_ESCAPE_PERCENT             = 0x00001000
        ; URL_ESCAPE_SEGMENT_ONLY        = 0x00002000
        ; URL_ESCAPE_AS_UTF8             = 0x00040000 (Win 7+)
        ; URL_ESCAPE_ASCII_URI_COMPONENT = 0x00080000 (Win 8+)
        ; ======================================================================================================================
        Url_Escape(Url, Flags := 0) {
            static CC := 4096
            Esc := Buffer(CC, 0)
            Return !DllCall("Shlwapi.dll\UrlEscape", "Str", Url, "Str", Esc, "UIntP", CC, "UInt", Flags, "UInt") ? Esc : ""
        }
        ; query_safe := UrlEncode(input)
        ; return query_safe

        ; UrlEncode(str, sExcepts := '-_.', enc := 'UTF-8') {
        ;     encoded := ''
        ;     hex     := '00'
        ;     buff    := Buffer(StrPut(str, enc)), StrPut(str, buff, enc)

        ;     loop {
        ;         if (!b := NumGet(buff, A_Index - 1, 'UChar')) {
        ;             break
        ;         }
        ;         ch := Chr(b)
        ;         if (                                ; IsAlnum() is not used because it is locale dependent
        ;             b >= 0x41 && b <= 0x5A ||       ; A-Z
        ;             b >= 0x61 && b <= 0x7A ||       ; a-z
        ;             b >= 0x30 && b <= 0x39 ||       ; 0-9
        ;             InStr(sExcepts, Chr(b), true)   ;
        ;         ) {
        ;             encoded .= Chr(b)
        ;         } else {
        ;             DllCall('msvcrt\swprintf', 'Str', hex, 'Str', '%%%02X', 'UChar', b, 'Cdecl')
        ;             encoded .= hex
        ;         }
        ;     }
        ;     return encoded
        ; }
    }
}

class EngineRegistry extends Map {
    CaseSense := 'Off'
}
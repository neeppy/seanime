// Fork-only. Lets a plain browser play torrent and debrid streams in the
// built-in player (VideoCore, the "nativeplayer" playback type), which
// upstream offers only in Seanime Denshi. Per device (localStorage) and off by
// default. The server needs no change: it already serves these streams over
// HTTP at {{SERVER_URL}}, which the client fills in with its own origin.
//
// Wired into upstream code by `// fork:` hooks, listed in fork/README.md.

import { ElectronPlaybackMethod, useCurrentDevicePlaybackSettings } from "@/app/(main)/_atoms/playback.atoms"
import { SettingsCard } from "@/app/(main)/settings/_components/settings-card"
import { Switch } from "@/components/ui/switch"
import { __isElectronDesktop__ } from "@/types/constants"
import { useAtom, useAtomValue } from "jotai"
import { atomWithStorage } from "jotai/utils"
import React from "react"
import { toast } from "sonner"

const NativePlayerLazyWrapper = React.lazy(() => import("@/app/(main)/_features/native-player/native-player-lazy-wrapper"))

// getOnInit, so the first render already knows and a stream started straight
// after page load picks the right player.
const fork_browserNativePlayerAtom = atomWithStorage<boolean>("fork-browser-native-player", false, undefined, { getOnInit: true })

/**
 * Whether torrent and debrid streams on this device open in the built-in
 * player: Denshi's own setting there, the fork's setting in a browser.
 */
export function useForkStreamsUseNativePlayer(): boolean {
    const { electronPlaybackMethod } = useCurrentDevicePlaybackSettings()
    const browserEnabled = useAtomValue(fork_browserNativePlayerAtom)
    return __isElectronDesktop__ ? electronPlaybackMethod === ElectronPlaybackMethod.NativePlayer : browserEnabled
}

/** Mounts the built-in player in a browser when enabled. Denshi mounts its own. */
export function ForkBrowserNativePlayer() {
    const enabled = useAtomValue(fork_browserNativePlayerAtom)
    if (__isElectronDesktop__ || !enabled) return null
    return (
        <React.Suspense fallback={null}>
            <NativePlayerLazyWrapper />
        </React.Suspense>
    )
}

/** The setting, for the playback settings page. Browser only. */
export function ForkBrowserNativePlayerSettings() {
    const [enabled, setEnabled] = useAtom(fork_browserNativePlayerAtom)
    if (__isElectronDesktop__) return null
    return (
        <SettingsCard
            title="Built-in player"
            className="border-[--border] bg-[--paper]"
        >
            <Switch
                label="Play torrent and debrid streams in the built-in player"
                help="Streams play right here in the browser, overriding the streaming choice below. The browser decodes the video itself, so formats it doesn't support (often 10-bit H.264 or AC3 audio) won't play. Saved on this device only."
                value={enabled}
                onValueChange={v => {
                    setEnabled(v)
                    toast.success("Playback settings updated")
                }}
            />
        </SettingsCard>
    )
}

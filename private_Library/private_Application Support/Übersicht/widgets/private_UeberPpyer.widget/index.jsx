/*
   This is a fork of https://github.com/aCluelessDanny/UeberPlayer
   The main reason for forking was to avoid using applescript for apple music interactions.
   Using applescript causes system-wide GPU stutters when interacting with apple music for whatever
   fucked up reason.

   To use this, you will need to run my fork of `nowplaying-cli` as a background service
   https://github.com/peppy/nowplaying-cli

   The binary is included alongside this widget for convenience.
 */

import { styled, run } from "uebersicht";
import getColors from './lib/getColors.js';
const _version = '1.4.0';

export const refreshFrequency = 1000;

/* CUSTOMIZATION (mess around here!)
You may need to refresh the widget after changing these settings
For more details about these settings: please visit https://github.com/aCluelessDanny/UeberPlayer#settings */

const options = {
  size: "small",                  // -> big (default) | medium | small | mini
  verticalPosition: "bottom",      // -> top (default) | center | bottom | "<number>" | "-<number>"
  horizontalPosition: "right",   // -> left (default) | center | right | "<number>" | "-<number>"
  alwaysShow: 0,                // -> 0 (default) | 1 | 2
  adaptiveColors: true,         // -> true (default) | false
  minContrast: 2.6,             // -> 2.6 (default) | number
  dualProgressBar: false,       // -> true | false (default)
  miniArtwork: false,           // -> true | false (default)
  cacheMaxDays: 15,             // -> 15 (default) | <number>
}

/* ROOT STYLING */

export const className = `
  pointer-events: none;
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  right: 0;
  font-family: "Jetbrains Mono", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
  color: white;

  * {
    box-sizing: border-box;
    padding: 0;
    border: 0;
    margin: 0;
  }
`;

/* EMOTION COMPONENTS */

const wrapperPos = ({ horizontal, vertical }) => {
  if (horizontal === "center" && vertical === "center") {
    return `
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
    `
  }

  let hPos, vPos;
  switch (horizontal) {
    case "left": hPos = `left: 20px;`; break;
    case "center": hPos = `left: 50%; transform: translateX(-50%);`; break;
    case "right": hPos = `right: 8px;`; break;
    default: hPos = horizontal.startsWith("-") ? `right: ${parseInt(horizontal) * -1}px;` : `left: ${horizontal}px;`; break;
  }
  switch (vertical) {
    case "top": vPos = `top: 20px;`; break;
    case "center": vPos = `top: 50%; transform: translateY(-50%);`; break;
    case "bottom": vPos = `bottom: 8px;`; break;
    default: vPos = vertical.startsWith("-") ? `bottom: ${parseInt(vertical) * -1}px;` : `top: ${vertical}px;`; break;
  }

  return `${hPos} ${vPos}`;
}

const Wrapper = styled("div")`
  position: absolute;
  overflow: hidden;
  box-shadow: 0 14px 30px 5px #0005;
  border-radius: 14px;
  opacity: ${props => props.show ? 1 : 0};
  background: ${props => (props.bg !== undefined) ? props.bg : "#00040000"};
  transition: all 0.6s cubic-bezier(0.22, 1, 0.36, 1);
  ${wrapperPos}

  &::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;
    z-index: -1;
  }

`;

const miniWrapperPos = ({ horizontal }) => {
  switch (horizontal) {
    case "left": return `text-align: left;`;
    case "center": return `text-align: center;`;
    case "right": return `text-align: right;`;
    default: return horizontal.startsWith("-") ? `text-align: right;` : `text-align: left;`;
  }
}

const MiniWrapper = styled(Wrapper)`
  border-radius: 10px;
  overflow: visible;
  box-shadow: none;
  background: transparent;
  ${miniWrapperPos}

  &::before {
    display: none;
  }
`

const ErrorWrapper = styled('div')`
  width: 420px;
  padding: 1em;
  text-align: center;
  font-size: .9em;

  * + * {
    margin-top: .4em;
  }

  h3 {
    font-style: italic;
    color: #ddd;
  }
`

const BigPlayer = styled("div")`
  display: flex;
  flex-direction: column;
  width: 240px;
`;

const MediumPlayer = styled(BigPlayer)`
  width: 180px;
`

const SmallPlayer = styled("div")`
  position: relative;
  display: flex;
  height: 50px;
  width: 400px;
`

const MiniPlayer = styled("div")`
  position: relative;
  display: flex;
  flex-direction: column;
  width: 400px;
  line-height: 1;

  * {
    text-shadow: 0px 0px 4px #0004, 0px 2px 12px #0004;
  }
`

const MiniInfo = styled("div")`
  display: flex;
  align-items: center;
`

const MiniDetails = styled("div")`
  flex: 1;

  > * + * {
    margin-top: .5em;
  }
`

const ArtworkWrapper = styled("div")`
  position: relative;
  width: 240px;
  height: 240px;

  &.medium {
    width: 180px;
    height: 180px;
  }

  &.small {
    width: 80px;
    height: 80px;
  }

  &.mini {
    width: 65px;
    height: 65px;
    border-radius: 4px;
    margin-right: 10px;
    overflow: hidden;
  }

  &::before {
    position: absolute;
    content: "";
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;
    border-radius: 14px;
    background: #fff1;
    z-index: -1;
  }

  &.mini::before {
    border-radius: 6px;
  }
`

const Artwork = styled("img")`
  position: absolute;
  height: 65%;
  width: 100%;
  overflow: hidden;
  object-fit: cover;
  border-radius: 0px;
  opacity: ${props => props.show ? 1 : 0};
`;

const Information = styled("div")`
  position: relative;
  padding: .5em .75em;
  line-height: 1.3;
  border-radius: 14px;
  backdrop-filter: ${options.adaptiveColors ? "blur(8px)" : "blur(8px) brightness(90%) contrast(80%) saturate(140%)"};

  > p {
    text-align: center;
    white-space: nowrap;
    overflow: visible;
    text-overflow: ellipsis;
  }

  &.small {
    flex: 1;
    width: 0;
    display: flex;
    flex-direction: column;
    justify-content: center;
    line-height: 1.2;
  }

  &.small > p {
    text-align: left;
  }
`

const Progress = styled("div")`
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: ${props => options.dualProgressBar && props.emptyColor ? (props.emptyColor + "80") : "transparent"};

  &::after {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    width: ${props => props.percent}%;
    background: ${props => props.progressColor ? props.progressColor : "white"};
    transition: width .6s cubic-bezier(0.22, 1, 0.36, 1);
  }

  &.small {
    top: initial;
    bottom: 0;
  }
  &.mini {
    position: relative;
    height: 4px;
    border-radius: 2px;
    background: ${props => options.dualProgressBar && props.emptyColor ? (props.emptyColor + "60") : "#0005"};
    box-shadow: 0 3px 5px -1px #0003;
    overflow: hidden;
    margin-top: 10px;
  }
`

const Track = styled("p")`
  font-weight: bold;
  font-size: .7em;
  color: ${props => props.color ? props.color : "inherit"};

  &::after {
    content: '';
    display: inline-block;
    width: 0;
  }

  &.small {
    font-size: .65em;
  }

  &.mini {
    font-size: 1.2em;
  }
`

const Artist = styled("p")`
  font-size: .7em;
  color: ${props => props.color ? props.color : "inherit"};

  &::after {
    content: '';
    display: inline-block;
    width: 0;
  }

  &.small {
    font-size: .65em;
  }

  &.mini {
    font-size: 1em;
  }
`

const Album = styled("p")`
  font-size: .65em;
  color: ${props => props.color ? props.color : "inherit"};
  opacity: .75;

  &::after {
    content: '';
    display: inline-block;
    width: 0;
  }

  &.small {
    font-size: .55em;
  }
`

/* UEBER-SPECIFIC STUFF */

export const init = (dispatch) => {
  // Initialize and clear cache of old artwork
  run(
    `mkdir -p UeberPpyer.widget/cache &&\
    find UeberPpyer.widget/cache -mindepth 1 -type f -mtime +${options.cacheMaxDays} -delete`
  );
};

export const command = "cat UeberPpyer.widget/lib/track";

export const initialState = {
  app: "",                                          // Current music software being used
  playing: false,                                   // If currently playing a soundtrack
  appleMusicError: false,                           // If online music is being played on Apple Music
  songChange: false,                                // If the song changed
  primaryColor: undefined,                          // Primary color from artwork
  secondaryColor: undefined,                        // Secondary color from artwork
  tercaryColor: undefined,                          // Tercary color from artwork
  artwork: {                                        // Artwork source URL to be used
    art1: "UeberPpyer.widget/default.png",           // Artwork to alternate with
    art2: "UeberPpyer.widget/default.png",           // Same as above
    alternate: true                                   // Flag to pick which artwork to display (for smooth transitions)
  },
  song: {                                           // Current song data
    track: "",                                        // Name of soundtrack
    artist: "",                                       // Name of artist
    album: "",                                        // Name of album
    localArtwork: "",                                 // Locally stored url for album artwork
    onlineArtwork: "",                                // Online url for album artwork
    duration: 0,                                      // Total duration of soundtrack in seconds
    elapsed: 0                                        // Total time elapsed in seconds
  },
  updateAvailable: false,                           // Flag for when an update's available
  updatePending: false,                             // Flag for when an update's about to happen
};

// Update state
export const updateState = ({ type, output, error }, previousState) => {
  switch (type) {
    case 'UB/COMMAND_RAN':
      return updateSongData(output, error, previousState);
    case 'GET_ART':
      if (options.adaptiveColors) {
        return getColors(output, previousState, options);
      } else {
        const { art1, art2, alternate } = previousState.artwork;
        return {
          ...previousState,
          songChange: false,
          primaryColor: undefined,
          secondaryColor: undefined,
          tercaryColor: undefined,
          artwork: {
            art1: alternate ? art1 : output.img.src,
            art2: !alternate ? art2 : output.img.src,
            alternate: !alternate
          }
        }
      }
    case 'DEFAULT_ART':
      const { art1, art2, alternate } = previousState.artwork;
      return {
        ...previousState,
        songChange: false,
        primaryColor: "#00040000",
        secondaryColor: "#ffffffff",
        tercaryColor: "#f85d73ff",
        artwork: {
          art1: alternate ? art1 : "UeberPpyer.widget/default.png",
          art2: !alternate ? art2 : "UeberPpyer.widget/default.png",
          alternate: !alternate
        }
      }
    default:
      console.error("Invalid dispatch type?");
      return previousState;
  }
}

/* FUNCTIONS */

// Update song metadata
const updateSongData = (output, error, previousState) => {
  // Check for errors
  if (error) {
    const err_output = { ...previousState, error: error };
    console.error(err_output);
    return err_output;
  }

  // Extract & parse applescript output
  let [
    playing,
    app,
    track,
    artist,
    album,
    artworkURL,
    artworkFilename,
    duration,
    elapsed,
    appleMusicError
  ] = output.trim().split("\n");

  playing = (playing === "true");
  appleMusicError = false;
  duration = Math.floor(parseFloat(duration));
  elapsed = Math.floor(parseFloat(elapsed));

  // State controller
  if (track !== previousState.song.track || album !== previousState.song.album) {    // Song change
    return {
      ...previousState,
      app,
      playing,
      appleMusicError,
      songChange: true,
      song: {
        track,
        artist,
        album,
        localArtwork: `UeberPpyer.widget/cache/${artworkFilename}`,
        onlineArtwork: artworkURL,
        duration,
        elapsed
      }
    }
  } else {  // Currently playing
    return {
      ...previousState,
      app,
      playing,
      appleMusicError,
      song: {
        ...previousState.song,
        elapsed
      }
    };
  }
}

// Prepare artwork
const prepareArtwork = (dispatch, song) => {
  // Use a dummy image to test images beforehand
  const img = new Image();

  // Attempts images in this order: Local -> Online -> Default
  img.onload = () => { dispatch({ type: "GET_ART", output: { img }})};
  img.onerror = () => {
    if (song.onlineArtwork !== "missing value" && song.onlineArtwork !== "" && img.src !== song.onlineArtwork) {
      // img.crossOrigin = 'anonymous';
      // img.src = song.onlineArtwork;
    } else {
      dispatch({ type: "DEFAULT_ART" });
    }
  }

  img.crossOrigin = 'anonymous';
  img.src = song.localArtwork;
}

// RENDERING //
// Artwork image
const ArtworkImage = ({ artwork: { art1, art2, alternate }, wrapperClass }) => (
  <ArtworkWrapper className={wrapperClass}>
    <Artwork src={art1} show={alternate}/>
    <Artwork src={art2} show={!alternate}/>
  </ArtworkWrapper>
)

// Big player component
const Big = ({ state, dispatch }) => {
  const {
    song: { track, artist, album, elapsed, duration },
    secondaryColor,
    tercaryColor,
    artwork,
    updateAvailable,
    updatePending
  } = state;

  return (
    <BigPlayer>
      <ArtworkImage artwork={artwork} wrapperClass='big'/>
      {updateAvailable && <UpdateNotif dispatch={dispatch} updatePending={updatePending} useBackground/>}
      <Information>
        <Progress progressColor={secondaryColor} emptyColor={tercaryColor} percent={elapsed / duration * 100}/>
        <Track className="small" color={secondaryColor}>{track}</Track>
        <Artist className="small" color={tercaryColor}>{artist}</Artist>
        <Album className="small" color={tercaryColor}>{album}</Album>
      </Information>
    </BigPlayer>
  )
}

// Medium player component
const Medium = ({ state, dispatch }) => {
  const {
    song: { track, artist, elapsed, duration },
    secondaryColor,
    tercaryColor,
    artwork,
    updateAvailable,
    updatePending
  } = state;

  return (
    <MediumPlayer>
      <ArtworkImage artwork={artwork} wrapperClass='medium'/>
      {updateAvailable && <UpdateNotif dispatch={dispatch} updatePending={updatePending} useBackground/>}
      <Information>
        <Progress progressColor={secondaryColor} emptyColor={tercaryColor} percent={elapsed / duration * 100}/>
        <Track color={secondaryColor}>{track}</Track>
        <Artist color={tercaryColor}>{artist}</Artist>
      </Information>
    </MediumPlayer>
  )
}

// Small player component
const Small = ({ state, dispatch }) => {
  const {
    song: { track, artist, album, elapsed, duration },
    secondaryColor,
    tercaryColor,
    artwork,
    updateAvailable,
    updatePending
  } = state;

  return (
    <SmallPlayer>
      <ArtworkImage artwork={artwork} wrapperClass='small'/>
      <Information className="small">
        <Track color={secondaryColor}>{track}</Track>
        <Artist color={tercaryColor}>{artist}</Artist>
        <Album color={tercaryColor}>{album}</Album>
        <Progress progressColor={secondaryColor} emptyColor={tercaryColor} className="small" percent={elapsed / duration * 100}/>
      </Information>
    </SmallPlayer>
  )
}

// Mini player component
const Mini = ({ state, dispatch }) => {
  const {
    song: { track, artist, elapsed, duration },
    primaryColor,
    secondaryColor,
    artwork,
    updateAvailable,
    updatePending
  } = state;

  return (
    <MiniPlayer>
      <MiniInfo>
        {options.miniArtwork && <ArtworkImage artwork={artwork} wrapperClass='mini'/>}
        <MiniDetails>
          <Track className="mini">{track}</Track>
          <Artist className="mini">{artist}</Artist>
        </MiniDetails>
      </MiniInfo>
      <Progress className="mini" progressColor={primaryColor} emptyColor={secondaryColor} percent={elapsed / duration * 100}/>
      {updateAvailable && <UpdateNotif dispatch={dispatch} updatePending={updatePending}/>}
    </MiniPlayer>
  )
}

// Render function
export const render = (state, dispatch) => {
  const { size, horizontalPosition, verticalPosition, alwaysShow } = options;
  const { app, playing, appleMusicError, songChange, primaryColor, secondaryColor, tercaryColor, artwork, song, updateAvailable, updatePending } = state;

  // Determine widget visability
  const showWidget = playing || (alwaysShow === 1 && app) || alwaysShow === 2;

  // When song changes, prepare artwork
  if (songChange) {
    prepareArtwork(dispatch, song);
  }

  // If Apple Music is playing online music, warn the user that it cannot get information for it
  if (appleMusicError) {
    return (
      <Wrapper show={showWidget} horizontal={horizontalPosition} vertical={verticalPosition}>
        <ErrorWrapper>
          <h3>Online Apple Music detected</h3>
          <p>Unfortunately, the widget is unable to access songs being streamed online through Apple Music.</p>
          <p>To fix this, please download your music to your library and play it locally from there.</p>
        </ErrorWrapper>
      </Wrapper>
    )
  }

  // Render
  return (size === "mini") ? (
    <MiniWrapper show={showWidget} horizontal={horizontalPosition} vertical={verticalPosition}>
      <Mini state={state} dispatch={dispatch}/>
    </MiniWrapper>
  ) : (
    <Wrapper show={showWidget} bg={primaryColor} horizontal={horizontalPosition} vertical={verticalPosition}>
      {size === 'big' && <Big state={state} dispatch={dispatch}/>}
      {size === 'medium' && <Medium state={state} dispatch={dispatch}/>}
      {size === 'small' && <Small state={state} dispatch={dispatch}/>}
    </Wrapper>
  )
};

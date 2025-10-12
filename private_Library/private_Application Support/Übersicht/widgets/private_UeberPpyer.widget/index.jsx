/*
   This is a fork of https://github.com/aCluelessDanny/UeberPlayer
   The main reason for forking was to avoid using applescript for apple music interactions.
   Using applescript causes system-wide GPU stutters when interacting with apple music for whatever
   fucked up reason.

   This now uses (and depends on) https://github.com/ungive/mediaremote-adapter.
   As of macOS 15.5, this is one remaining method of getting system-wide now-playing information.

   Install it via brew.
 */

import { styled, run } from "uebersicht";
import getColors from './lib/getColors.js';

export const refreshFrequency = 1000;

const options = {
  verticalPosition: "bottom",
  horizontalPosition: "right",
  alwaysShow: 0,
  adaptiveColors: true,
  minContrast: 2.6,
  dualProgressBar: false,
  cacheMaxDays: 15,
};

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

const wrapperPos = ({ horizontal, vertical }) => {
  if (horizontal === "center" && vertical === "center") {
    return `
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
    `;
  }
  let hPos, vPos;
  switch (horizontal) {
    case "left":
      hPos = `left: 20px;`;
      break;
    case "center":
      hPos = `left: 50%; transform: translateX(-50%);`;
      break;
    case "right":
      hPos = `right: 8px;`;
      break;
    default:
      hPos = horizontal.startsWith("-")
        ? `right: ${parseInt(horizontal) * -1}px;`
        : `left: ${horizontal}px;`;
  }
  switch (vertical) {
    case "top":
      vPos = `top: 20px;`;
      break;
    case "center":
      vPos = `top: 50%; transform: translateY(-50%);`;
      break;
    case "bottom":
      vPos = `bottom: 8px;`;
      break;
    default:
      vPos = vertical.startsWith("-")
        ? `bottom: ${parseInt(vertical) * -1}px;`
        : `top: ${vertical}px;`;
  }
  return `${hPos} ${vPos}`;
};

const Wrapper = styled("div")`
  position: absolute;
  overflow: hidden;
  box-shadow: 0 14px 30px 5px #0005;
  border-radius: 14px;
  opacity: ${props => (props.show ? 1 : 0)};
  background: ${props => (props.bg !== undefined ? props.bg : "#00040000")};
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

const SmallPlayer = styled("div")`
  position: relative;
  display: flex;
  height: 50px;
  width: 400px;
`;

const ArtworkWrapper = styled("div")`
  position: relative;
  width: 240px;
  height: 240px;
  &.small {
    width: 80px;
    height: 80px;
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
`;

const Artwork = styled("img")`
  position: absolute;
  height: 65%;
  width: 100%;
  overflow: hidden;
  object-fit: cover;
  border-radius: 0;
  opacity: ${props => (props.show ? 1 : 0)};
`;

const Information = styled("div")`
  position: relative;
  padding: .5em .75em;
  line-height: 1.3;
  border-radius: 14px;
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
`;

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
`;

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
`;

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
`;

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
`;

export const init = dispatch => {
  run(
    `mkdir -p UeberPpyer.widget/cache &&\
    find UeberPpyer.widget/cache -mindepth 1 -type f -mtime +${options.cacheMaxDays} -delete`
  );
};

export const command = "/opt/homebrew/bin/media-control get";

export const initialState = {
  app: "",
  playing: false,
  songChange: false,
  primaryColor: undefined,
  secondaryColor: undefined,
  tercaryColor: undefined,
  artwork: {
    art1: "UeberPpyer.widget/default.png",
    art2: "UeberPpyer.widget/default.png",
    alternate: true
  },
  song: {
    track: "",
    artist: "",
    album: "",
    localArtwork: "",
    onlineArtwork: "",
    duration: 0,
    elapsed: 0
  },
  updateAvailable: false,
  updatePending: false,
};

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
        tercaryColor: "#c49fff",
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
};

const updateSongData = (output, error, previousState) => {
  if (error) {
    const err_output = { ...previousState, error };
    console.error(err_output);
    return err_output;
  }

  const data = JSON.parse(output);

  if (!data)
    return previousState;

  const playing = data.playing;
  const track = data.title;
  const artist = data.artist;
  const album = data.album;
  const duration = data.duration;
  const timeDiff = Date.now() - new Date(data.timestamp).getTime();
  let elapsed = data.elapsedTime;
  if (data.playing) {
    elapsed += timeDiff / 1000;
  }
  let localArtwork = null;
  if (data.artworkMimeType) {
    localArtwork = `data:${data.artworkMimeType};base64,${data.artworkData}`;
  }
  if (
    (localArtwork && !previousState?.song.localArtwork) ||
    track !== previousState?.song.track ||
    album !== previousState?.song.album
  ) {
    return {
      ...previousState,
      playing,
      songChange: true,
      song: {
        track,
        artist,
        album,
        localArtwork,
        duration,
        elapsed
      }
    };
  } else {
    return {
      ...previousState,
      playing,
      song: {
        ...previousState.song,
        elapsed
      }
    };
  }
};

const prepareArtwork = (dispatch, song) => {
  const img = new window.Image();
  img.onload = () => {
    dispatch({ type: "GET_ART", output: { img } });
  };
  img.onerror = () => {
    dispatch({ type: "DEFAULT_ART" });
  };
  img.crossOrigin = 'anonymous';
  img.src = song.localArtwork;
};

const ArtworkImage = ({ artwork: { art1, art2, alternate }, wrapperClass }) => (
  <ArtworkWrapper className={wrapperClass}>
    <Artwork src={art1} show={alternate} />
    <Artwork src={art2} show={!alternate} />
  </ArtworkWrapper>
);

const Small = ({ state }) => {
  const {
    song: { track, artist, album, elapsed, duration },
    secondaryColor,
    tercaryColor,
    artwork,
  } = state;
  return (
    <SmallPlayer>
      <ArtworkImage artwork={artwork} wrapperClass='small' />
      <Information className="small">
        <Track color={secondaryColor}>{track}</Track>
        <Artist color={tercaryColor}>{artist}</Artist>
        <Album color={tercaryColor}>{album}</Album>
        <Progress progressColor={secondaryColor} emptyColor={tercaryColor} className="small" percent={duration ? (elapsed / duration) * 100 : 0} />
      </Information>
    </SmallPlayer>
  );
};

export const render = (state, dispatch) => {
  const { horizontalPosition, verticalPosition, alwaysShow } = options;
  const { app, playing, songChange, primaryColor } = state;
  const showWidget = playing || (alwaysShow === 1 && app) || alwaysShow === 2;
  if (songChange) {
    prepareArtwork(dispatch, state.song);
  }
  return (
    <Wrapper show={showWidget} bg={primaryColor} horizontal={horizontalPosition} vertical={verticalPosition}>
      <Small state={state} />
    </Wrapper>
  );
};

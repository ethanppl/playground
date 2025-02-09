# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Fixed

- Set endpoint config URL to `playground.ethanppl.com`
- Handle error when player concurrently start/end games
- Fix Super tic tac toe: timer round off is incorrect

## [0.2.5] - 2024-12-15

### Added

- Support quit room and remove the user from its room
- Support host removing player from its room

### Changed

- Images are in webp format by default, with png as fallback

## [0.2.4] - 2024-10-12

### Fixed

- Fix sentry config and update deployment documentation accordingly

## [0.2.3] - 2024-10-12

### Added

- Super tic tac toe: timer of current move + cumulative of each player
- Add sentry for error capturing

### Changed

- Super tic tac toe: fix is draw logic
- Make the restart/new game buttons smaller

## [0.2.2] - 2024-09-13

### Changed

- Create room and join room forms don't automatically convert name uppercase
- Better icons and borders for super tic-tac-toe

## [0.2.1] - 2024-08-24

### Added

- List games page
- Add how to play instructions for each game

### Changed

- Replace all `multi-hangman` with `super-hangman` in code

## [0.2.0] - 2024-08-16

### Added

- Add super tic-tac-toe game

### Changed

- Name the Multi Hangman game as Super Hangman

## [0.1.1] - 2024-08-11

### Added

- Set up GitHub actions for checks

### Fixed

- Wrong `CMD` in deployment script and updated the deployment doc

## [0.1.0] - 2024-08-11

### Added

Playground engine

- Create the playground engine for creating and joining room
- The room process support starting and ending a game
- The room process forward moves to game module
- The room process persist the game state initialized or updated by the game
  modules
- The room process broadcast the room state and the room liveview subscribe it

Home page

- Create room with host name
- Join room with code or with URL

Room liveview

- Select game page when there is no active game
- Render the component of the active game with the game state passed in
- Subscribe and display notifications from games
- Restart, quit game or quit room with the info box from the top right

Games

- `tic-tac-toe` - Added as a demo for game turns, notifications and display
  game states
- `multi-hangman` - Added game with select secret word, render guess screen for
  each player, take turns guess letter, guess words at any time

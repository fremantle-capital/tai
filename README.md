# Tai - Orchestrate Your Trading

[![Build Status](https://github.com/fremantle-industries/tai/workflows/test/badge.svg?branch=main)](https://github.com/fremantle-industries/tai/actions?query=workflow%3Atest)
[![Coverage Status](https://coveralls.io/repos/github/fremantle-industries/tai/badge.svg?branch=main)](https://coveralls.io/github/fremantle-industries/tai?branch=main)
[![hex.pm version](https://img.shields.io/hexpm/v/tai.svg?style=flat)](https://hex.pm/packages/tai)

A composable, real time, market data and trade execution toolkit. Built with [Elixir](https://elixir-lang.org/), runs on the [Erlang virtual machine](http://erlang.org/faq/implementations.html)

[Getting Started](./docs/GETTING_STARTED.md) | [Built with Tai](./docs/BUILT_WITH_TAI.md) | [Install](#install) | [Usage](#usage) | [Commands](./docs/COMMANDS.md) | [Architecture](./docs/ARCHITECTURE.md) | [Examples](./apps/examples) | [Configuration](./docs/CONFIGURATION.md) | [Observability](./docs/OBSERVABILITY.md)

## What Can I Do? TLDR;

Stream market data to create and manage orders with a near-uniform API across multiple venues

Here's an example of an advisor that logs the spread between multiple products on multiple venues

[![asciicast](https://asciinema.org/a/259561.svg)](https://asciinema.org/a/259561)

## Supported Venues

| Venues | Live Order Book | Accounts | Active Orders | Passive Orders | Products | Fees |
| ------ | :-------------: | :------: | :-----------: | :------------: | :------: | :--: |
| FTX    |       [x]       |   [x]    |      [x]      |      [x]       |   [x]    | [x]  |
| OkEx   |       [x]       |   [x]    |      [x]      |      [x]       |   [x]    | [x]  |
| BitMEX |       [x]       |   [x]    |      [x]      |      [x]       |   [x]    | [x]  |

## Venues In Progress

| Venue    | Live Order Book | Accounts | Active Orders | Passive Orders | Products | Fees |
| -------- | :-------------: | :------: | :-----------: | :------------: | :------: | :--: |
| Binance  |       [x]       |   [x]    |      [x]      |      [ ]       |   [x]    | [x]  |
| Deribit  |       [x]       |   [x]    |      [ ]      |      [ ]       |   [x]    | [x]  |
| GDAX     |       [x]       |   [x]    |      [ ]      |      [ ]       |   [x]    | [x]  |
| Huobi    |       [x]       |   [ ]    |      [ ]      |      [ ]       |   [x]    | [ ]  |
| Bybit    |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| bit.com  |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| Bitfinex |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| BTSE     |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| Kraken   |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| KuCoin   |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| BitMax   |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| MXC      |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| PrimeXBT |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| Gate.io  |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| Coinflex |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |
| bitFlyer |       [ ]       |   [ ]    |      [ ]      |      [ ]       |   [ ]    | [ ]  |

## Install

`tai` requires Elixir 1.10+ & Erlang/OTP 22+. Add `tai` to your list of dependencies in `mix.exs`

```elixir
def deps do
  [{:tai, "~> 0.0.66"}]
end
```

Create an `.iex.exs` file in the root of your project and import the `tai` helper

```elixir
# .iex.exs
Application.put_env(:elixir, :ansi_enabled, true)

import Tai.IEx
```

## Usage

`tai` runs as an OTP application.

During development we can leverage `mix` to compile and run our application with an
interactive Elixir shell that imports the set of `tai` helper [commands](./docs/COMMANDS.md).

```bash
iex -S mix
```

## Help Wanted :)

If you think this `tai` thing might be worthwhile and you don't see a feature
or venue listed we would love your contributions to add them! Feel free to
drop us an email or open a Github issue.

## Authors

- Alex Kwiatkowski - alex+git@fremantle.io

## License

`tai` is released under the [MIT license](./LICENSE.md)

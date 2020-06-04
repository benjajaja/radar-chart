# Radar Chart

A small library to display just one type of charts: radar charts, also known as web chart, spider chart, spider web chart, star chart, star plot, cobweb chart, irregular polygon, polar chart, or Kiviat diagram.

Sample output:  
![Sample output](https://github.com/gipsy-king/radar-chart/blob/master/sample_output.svg?raw=true)

Ellie demo playground:  
https://ellie-app.com/93J93BR7dGHa1

## Installation

Run the following command in the root of your project

```shell
$ elm install gipsy-king/radar-chart
```

and import the library in an elm file like this 

```elm
import RadarChart
```

## Usage

```elm
RadarChart.view
  RadarChart.defaultOptions
  [ "Values", "Variables", "Conditionals", "Loops", "Functions", "Programs" ]
  [ { color = "yellow", data = [ 120, 500, 310, 130, 300, 180 ] } ]
```

See the documentation for more information on what the parameters are!

## Documentation

Find the documentation on [Elm's package website](http://package.elm-lang.org/packages/gipsy-king/radar-chart).

## Development

### Setup

```shell
$ cd examples
$ elm reactor
```

and open [examples](https://localhost:8000).


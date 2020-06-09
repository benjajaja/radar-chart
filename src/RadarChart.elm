module RadarChart exposing
    ( DatumSeries
    , view, defaultOptions, simpleLabels
    , Options, AxisStyle(..), LineStyle(..), Maximum(..), customLabels
    , LabelMaker, Point, TextAlign
    )

{-|


# Simple chart data

@docs DatumSeries


# Show a radar chart

@docs view, defaultOptions, simpleLabels


# Customize chart a bit

@docs Options, AxisStyle, LineStyle, Maximum, customLabels


# Customize chart labels completely

@docs LabelMaker, Point, TextAlign

-}

import Svg exposing (Svg, circle, svg, text, text_)
import Svg.Attributes exposing (dominantBaseline, fill, fillOpacity, fontSize, stroke, strokeLinecap, strokeLinejoin, strokeWidth, textAnchor, viewBox)


{-| You can have multiple "series", or polygons, on one chart.
The `data` list should be of same size as axis labels.
-}
type alias DatumSeries =
    { color : String
    , data : List Float
    }


{-| Render a radar chart with options, labels, and some values
-}
view : Options -> List (LabelMaker msg) -> List DatumSeries -> Svg msg
view options labels series =
    let
        axisCount =
            series
                |> List.map (.data >> List.length)
                |> List.maximum
                |> Maybe.withDefault 3
    in
    Svg.svg [ viewBox "0 0 100 100" ] <|
        List.concat (List.map (axis options axisCount) <| List.range 0 axisCount)
            ++ (List.concat <|
                    List.map
                        (\{ color, data } ->
                            lines
                                options
                                axisCount
                                color
                                data
                                (case options.maximum of
                                    FixedMax n ->
                                        n

                                    Infer ->
                                        Maybe.withDefault 1 <| List.maximum data
                                )
                                []
                        )
                        series
               )
            ++ axisLabels options axisCount labels


{-| Get a default options object.
-}
defaultOptions : Options
defaultOptions =
    { maximum = Infer
    , margin = 0.333
    , strokeWidth = 0.5
    , axisColor = "darkgrey"
    , axisStyle = Web 6
    , lineStyle = Empty
    }


{-| Default text labels, positioned conveniently
-}
simpleLabels : List String -> List (LabelMaker msg)
simpleLabels labels =
    List.indexedMap axisLabel labels


{-| Custom labels: use a list of anything, and a function that maps the elements
together with position/alignment SVG attributes to `Svg msg`.
-}
customLabels : List a -> (a -> List (Svg.Attribute msg) -> Svg msg) -> List (LabelMaker msg)
customLabels list fn =
    List.map
        (\a ->
            \point align ->
                fn a <| labelAttributes point align
        )
        list


{-| Chart options:

  - `margin` Between 0 and 1, to leave some space for labels
  - `strokeWidth` For all lines, see <https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/stroke-width>
  - `axisColor` axis stroke color, any valid HTML color string (hex, color-name, rgba(...), etc.)
  - `axisStyle` see `AxisStyle`
  - `lineStyle` see `LineStyle`

-}
type alias Options =
    { maximum : Maximum
    , margin : Float
    , strokeWidth : Float
    , axisColor : String
    , axisStyle : AxisStyle
    , lineStyle : LineStyle
    }


{-| Axis style:

  - `Minimal` is just a line
  - `Web count` is a web with `count` "divisions"

-}
type AxisStyle
    = Minimal
    | Web Int


{-| The line style can be `Empty` (just lines) or `Filled opacity` (more like an area chart).
-}
type LineStyle
    = Empty
    | Filled Float


{-| Fixed axis maximum or use highest data point of series
-}
type Maximum
    = FixedMax Float
    | Infer


{-| You can even completely make your own attributes and everything
-}
type alias LabelMaker msg =
    Point -> TextAlign -> Svg msg


{-| Point in SVG, suitable for `x` and `y` attributes of text
-}
type alias Point =
    ( Float, Float )


{-| Text align is simply suitable values for `dominant-baseline` and `text-anchor`, respectively.
-}
type alias TextAlign =
    ( String, String )


lines : Options -> Int -> String -> List Float -> Float -> List Point -> List (Svg msg)
lines options count color list max result =
    case list of
        [] ->
            Svg.polygon
                ([ strokeWidth <| String.fromFloat options.strokeWidth
                 , stroke color
                 , Svg.Attributes.points <|
                    String.join " " <|
                        List.map (\( x, y ) -> String.join "," [ String.fromFloat x, String.fromFloat y ]) result
                 , strokeLinejoin "round"
                 ]
                    ++ (case options.lineStyle of
                            Filled opacity ->
                                [ fill color, fillOpacity <| String.fromFloat opacity ]

                            _ ->
                                [ fill "none" ]
                       )
                )
                []
                :: List.map
                    (\( x, y ) ->
                        circle
                            [ Svg.Attributes.cx <| String.fromFloat x
                            , Svg.Attributes.cy <| String.fromFloat y
                            , Svg.Attributes.r "0.5"
                            , stroke color
                            ]
                            []
                    )
                    result

        a :: tail ->
            let
                ( x, y ) =
                    pointOnCircle count (count - 1 - List.length tail) fullRadius (fullRadius * a / max) options.margin
            in
            lines options count color tail max <|
                result
                    ++ [ ( x, y ) ]


axis : Options -> Int -> Int -> List (Svg msg)
axis options count i =
    let
        ( x, y ) =
            pointOnCircle count i fullRadius fullRadius options.margin
    in
    Svg.line
        [ Svg.Attributes.x1 <| String.fromFloat fullRadius
        , Svg.Attributes.y1 <| String.fromFloat fullRadius
        , Svg.Attributes.x2 <| String.fromFloat x
        , Svg.Attributes.y2 <| String.fromFloat y
        , strokeWidth <| String.fromFloat options.strokeWidth
        , stroke options.axisColor
        ]
        []
        :: (case options.axisStyle of
                Minimal ->
                    []

                Web divisions ->
                    List.range 1 divisions
                        |> List.map (\d -> toFloat d / toFloat divisions)
                        |> List.map (webLine options count i)
           )


webLine : Options -> Int -> Int -> Float -> Svg msg
webLine options count i segment =
    let
        ( x1, y1 ) =
            pointOnCircle count i fullRadius (fullRadius * segment) options.margin

        ( x2, y2 ) =
            pointOnCircle count (i - 1) fullRadius (fullRadius * segment) options.margin
    in
    Svg.line
        [ Svg.Attributes.x1 <| String.fromFloat x1
        , Svg.Attributes.y1 <| String.fromFloat y1
        , Svg.Attributes.x2 <| String.fromFloat x2
        , Svg.Attributes.y2 <| String.fromFloat y2
        , strokeWidth <| String.fromFloat options.strokeWidth
        , stroke options.axisColor
        , strokeLinecap "round"
        ]
        []


axisLabels : Options -> Int -> List (LabelMaker msg) -> List (Svg msg)
axisLabels options count fns =
    List.indexedMap
        (\i fn ->
            let
                point =
                    pointOnCircle count i fullRadius fullRadius <| options.margin * 0.9

                anchors_ =
                    anchors count i
            in
            fn point anchors_
        )
        fns


axisLabel : Int -> String -> Point -> TextAlign -> Svg msg
axisLabel _ label point align =
    Svg.text_
        ((fontSize <| String.fromFloat 2.0)
            :: labelAttributes point align
        )
        [ text label ]


labelAttributes : Point -> TextAlign -> List (Svg.Attribute msg)
labelAttributes ( x, y ) ( vert, horiz ) =
    [ Svg.Attributes.x <| String.fromFloat <| x
    , Svg.Attributes.y <| String.fromFloat <| y
    , dominantBaseline vert
    , textAnchor horiz
    ]


pointOnCircle : Int -> Int -> Float -> Float -> Float -> Point
pointOnCircle steps i centerRadius radius margin =
    let
        theta =
            turns ((1 / toFloat steps * toFloat i) - 0.25)
    in
    ( centerRadius + (radius * cos theta * (1 - margin))
    , centerRadius + (radius * sin theta * (1 - margin))
    )


anchors : Int -> Int -> ( String, String )
anchors steps i =
    let
        theta =
            1 / toFloat steps * toFloat i

        vert =
            if theta < 0.25 || theta > 0.75 then
                "baseline"

            else if theta == 0.25 || theta == 0.75 then
                "middle"

            else
                "hanging"

        horiz =
            if theta == 0 || theta == 0.5 then
                "middle"

            else if theta < 0.5 then
                "start"

            else
                "end"
    in
    ( vert, horiz )


fullRadius : Float
fullRadius =
    50

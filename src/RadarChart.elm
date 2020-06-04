module RadarChart exposing (AxisStyle(..), DatumSeries, LineStyle(..), Options, defaultOptions, view)

import Svg exposing (Svg, circle, svg, text, text_)
import Svg.Attributes exposing (dominantBaseline, fill, fillOpacity, fontSize, stroke, strokeLinecap, strokeLinejoin, strokeWidth, textAnchor, viewBox)


{-| Render a radar chart with options, labels, and some values
-}
view : Options -> List String -> List DatumSeries -> Svg msg
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
                                (Maybe.withDefault 1 <| List.maximum <| data)
                                []
                        )
                        series
               )
            ++ List.indexedMap (axisLabel options axisCount) labels


type alias DatumSeries =
    { color : String
    , data : List Float
    }


{-| Chart styling
-}
type alias Options =
    { fontSize : Float
    , margin : Float
    , strokeWidth : Float
    , axisColor : String
    , axisStyle : AxisStyle
    , lineStyle : LineStyle
    }


type AxisStyle
    = Minimal
    | Web Int


type LineStyle
    = Empty
    | Filled Float


type alias Point =
    ( Float, Float )


{-| Get a default options object
-}
defaultOptions : Options
defaultOptions =
    { fontSize = 3.0
    , margin = 0.333
    , strokeWidth = 0.5
    , axisColor = "darkgrey"
    , axisStyle = Web 6
    , lineStyle = Empty
    }


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



{-
   Svg.line
       [ Svg.Attributes.x1 <| String.fromFloat xFrom
       , Svg.Attributes.y1 <| String.fromFloat yFrom
       , Svg.Attributes.x2 <| String.fromFloat x
       , Svg.Attributes.y2 <| String.fromFloat y
       , strokeWidth <| String.fromFloat options.strokeWidth
       , stroke "green"
       ]
       []
       :: result
       ++ [ circle
               [ Svg.Attributes.cx <| String.fromFloat x
               , Svg.Attributes.cy <| String.fromFloat y
               , Svg.Attributes.r "0.5"
               , stroke "green"
               ]
               []
          ]
-}


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


axisLabel : Options -> Int -> Int -> String -> Svg msg
axisLabel options count i label =
    let
        ( x, y ) =
            pointOnCircle count i fullRadius fullRadius <| options.margin * 0.9

        ( vertAnchor, horizAnchor ) =
            anchors count i
    in
    Svg.text_
        [ fontSize <| String.fromFloat options.fontSize
        , Svg.Attributes.x <| String.fromFloat <| x
        , Svg.Attributes.y <| String.fromFloat <| y
        , textAnchor horizAnchor
        , dominantBaseline vertAnchor
        ]
        [ Svg.text label ]


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

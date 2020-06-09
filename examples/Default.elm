module Default exposing (main)

import Html
import Html.Attributes
import RadarChart exposing (view)
import Svg
import Svg.Attributes


main : Html.Html msg
main =
    Html.div
        [ Html.Attributes.style "font-family" "sans" ]
        [ Html.div [] [ Html.text "Default options:" ]
        , RadarChart.view
            RadarChart.defaultOptions
            (RadarChart.simpleLabels [ "Values", "Variables", "Conditionals", "Loops", "Functions", "Programs" ])
            [ { color = "#333333", data = List.take 6 someData } ]
        , Html.div [] [ Html.text "Minimal axis, filled area, custom labels with tooltips:" ]
        , RadarChart.view
            { maximum = RadarChart.FixedMax 500
            , margin = 0.333
            , strokeWidth = 1
            , axisColor = "lightgrey"
            , axisStyle = RadarChart.Minimal
            , lineStyle = RadarChart.Filled (2 / 3)
            }
            (RadarChart.customLabels
                [ ( "Unit", "Unit tests" )
                , ( "Integration", "Integration tests" )
                , ( "E2E", "End-to-end tests" )
                , ( "QA", "Quality assurance testing" )
                , ( "Monitoring", "Production monitoring" )
                ]
                (\( label, tooltip ) attrs ->
                    Svg.text_
                        ((Svg.Attributes.fontSize <| String.fromFloat 1.5)
                            :: attrs
                        )
                        [ Svg.text label, Svg.title [] [ Svg.text tooltip ] ]
                )
            )
            [ { color = "blue", data = List.drop 2 someData }
            , { color = "red", data = List.take 5 someData }
            ]
        ]


someData =
    [ 120, 500, 310, 130, 300, 180, 444 ]

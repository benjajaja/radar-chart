module Default exposing (main)

import Html
import Html.Attributes
import RadarChart exposing (view)


main : Html.Html msg
main =
    Html.div
        [ Html.Attributes.style "font-family" "sans" ]
        [ Html.div [] [ Html.text "Default options:" ]
        , RadarChart.view
            RadarChart.defaultOptions
            [ "Values", "Variables", "Conditionals", "Loops", "Functions", "Programs" ]
            [ { color = "#333333", data = List.take 6 someData } ]
        , Html.div [] [ Html.text "Minimal axis, filled area:" ]
        , RadarChart.view
            { maximum = RadarChart.FixedMax 500
            , fontSize = 2.0
            , margin = 0.333
            , strokeWidth = 1
            , axisColor = "lightgrey"
            , axisStyle = RadarChart.Minimal
            , lineStyle = RadarChart.Filled (2 / 3)
            }
            [ "Unit", "Integration", "End-to-end", "QA", "Monitoring" ]
            [ { color = "blue", data = List.drop 2 someData }
            , { color = "red", data = List.take 5 someData }
            ]
        ]


someData =
    [ 120, 500, 310, 130, 300, 180, 444 ]

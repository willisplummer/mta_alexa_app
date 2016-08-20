module Routing exposing (..)

import String
import Navigation
import UrlParser exposing (..)


type Route
    = LoginRoute
    | SignupRoute
    | HomeRoute
    | NotFoundRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ format SignupRoute (s "")
        , format SignupRoute (s "signup")
        , format HomeRoute (s "home")
        , format LoginRoute (s "login")
        ]


hashParser : Navigation.Location -> Result String Route
hashParser location =
    location.hash
        |> String.dropLeft 1
        |> parse identity matchers


parser : Navigation.Parser (Result String Route)
parser =
    Navigation.makeParser hashParser


routeFromResult : Result String Route -> Route
routeFromResult result =
    case result of
        Ok route ->
            route

        Err string ->
            NotFoundRoute

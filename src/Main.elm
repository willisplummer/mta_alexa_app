module Main exposing (..)

import Navigation
import Authenticate
import Routing exposing (..)
import Html exposing (..)
import Html.App as App
import StopsList


--


main : Program ( Maybe String, Maybe String )
main =
    Navigation.programWithFlags Routing.parser
        { init = init
        , subscriptions = subscriptions
        , view = view
        , urlUpdate = urlUpdate
        , update = update
        }



-- init


init : ( Maybe String, Maybe String ) -> Result String Route -> ( Model, Cmd Msg )
init ( token, email ) result =
    let
        ( list, listMsgs ) =
            StopsList.init

        creds =
            case ( token, email ) of
                ( Just token, Just email ) ->
                    Just (Authenticate.ActiveUserCreds token email)

                _ ->
                    Nothing

        ( authenticate, authenticateMsgs ) =
            Authenticate.init creds

        currentRoute =
            routeFromResult result
    in
        ( { authentication = authenticate, stopsList = list, route = currentRoute, token = token }
        , Cmd.batch
            [ Cmd.map StopsList listMsgs
            , Cmd.map Authenticate authenticateMsgs
            ]
        )



-- urlUpdate


urlUpdate : Result String Route -> Model -> ( Model, Cmd Msg )
urlUpdate result model =
    let
        currentRoute =
            Routing.routeFromResult result
    in
        ( { model | route = currentRoute }, Cmd.none )



-- MODEL


type alias Model =
    { authentication : Authenticate.Model
    , stopsList : StopsList.Model
    , route : Routing.Route
    , token : Maybe String
    }


type Page
    = SignUpPage
    | LoginPage
    | HomePage



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE


type Msg
    = StopsList StopsList.Msg
    | Authenticate Authenticate.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StopsList subMsg ->
            let
                ( list, listCmds ) =
                    StopsList.update subMsg model.stopsList
            in
                ( { model | stopsList = list }
                , Cmd.map StopsList listCmds
                )

        Authenticate subMsg ->
            let
                ( authenticate, authenticateCmds ) =
                    Authenticate.update subMsg model.authentication
            in
                ( { model | authentication = authenticate }
                , Cmd.map Authenticate authenticateCmds
                )



-- VIEW


view : Model -> Html Msg
view model =
    case model.route of
        LoginRoute ->
            --Login.view
            div [] [ text "Login" ]

        SignupRoute ->
            App.map
                (\msg -> Authenticate msg)
                (Authenticate.view model.authentication)

        HomeRoute ->
            App.map
                (\msg -> StopsList msg)
                (StopsList.view model.stopsList)

        NotFoundRoute ->
            div [] [ text "NOT FOUND" ]

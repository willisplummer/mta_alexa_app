port module Main exposing (..)

import Navigation exposing (..)
import Authenticate exposing (..)
import Routing exposing (..)
import Html exposing (..)
import Html.App as App exposing (..)
import Html.Events exposing (onClick)
import StopsList
import Http
import Json.Decode as Json
import Json.Encode as JS
import Task


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

        ( authenticate, authenticateMsgs ) =
            Authenticate.init (Authenticate.ActiveUserCreds token email)

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


port setToken : Maybe String -> Cmd msg


type Msg
    = StopsList StopsList.Msg
    | SetSessionToken (Maybe String)
    | Login
    | FetchFail Http.Error
    | FetchSucceed String
    | Logout
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

        SetSessionToken token ->
            ( model
            , setToken token
            )

        Login ->
            ( model, loginEndpoint model )

        Logout ->
            ( { model | token = Nothing }, setToken Nothing )

        FetchFail _ ->
            ( model, Cmd.none )

        FetchSucceed token ->
            ( { model | token = Just token }, setToken (Just token) )

        Authenticate subMsg ->
            let
                ( authenticate, authenticateCmds ) =
                    Authenticate.update subMsg model.authentication
            in
                ( { model | authentication = authenticate }
                , Cmd.map Authenticate authenticateCmds
                )


loginEndpoint : model -> Cmd Msg
loginEndpoint model =
    let
        url =
            "http://localhost:4567/elm-login.json"

        body =
            Http.stringData "user"
                (JS.encode 0
                    (JS.object
                        [ ( "email", JS.string "willisplummer@gmail.com" )
                        , ( "password", JS.string "testtest" )
                        ]
                    )
                )
    in
        Task.perform FetchFail FetchSucceed (Http.post decodeLoginResponse url (Http.multipart [ body ]))


decodeLoginResponse : Json.Decoder String
decodeLoginResponse =
    Json.at [ "token" ] Json.string



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

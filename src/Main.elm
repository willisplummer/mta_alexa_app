port module Main exposing (..)

import Html exposing (..)
import Html.App as App exposing (..)
import Html.Events exposing (onClick)
import Signup
import Routes
import StopsList
import Http
import Json.Decode as Json
import Json.Encode as JS
import Task


--


main : Program (Maybe String)
main =
    App.programWithFlags { init = init, subscriptions = subscriptions, view = view, update = update }



-- MODEL


type alias Model =
    { signUp : Signup.Model
    , stopsList : StopsList.Model
    , page : Routes.Model
    , token : Maybe String
    }


type Page
    = SignUpPage
    | LoginPage
    | HomePage


init : Maybe String -> ( Model, Cmd Msg )
init token =
    let
        ( list, listMsgs ) =
            StopsList.init
    in
        ( { signUp = Signup.init, stopsList = list, page = Routes.model, token = token }
        , Cmd.batch
            [ Cmd.map StopsList listMsgs
            ]
        )



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


loginEndpoint : model -> Cmd Msg
loginEndpoint model =
    let
        url =
            "http://localhost:4567/endpoint.json"

        body =
            Http.stringData "user"
                (JS.encode 0
                    (JS.object
                        [ ( "email", JS.string "willisplummer@gmail.com" )
                        , ( "password", JS.string "testpw" )
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
    let
        tokenText =
            case model.token of
                Just token ->
                    token

                Nothing ->
                    "logged out"
    in
        div []
            [ button [ onClick (Login) ] [ text "Get a token" ]
            , button [ onClick (Logout) ] [ text "Logout" ]
            , text tokenText
            , App.map
                (\msg -> StopsList msg)
                (StopsList.view model.stopsList)
            ]

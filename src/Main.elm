module Main exposing (..)

import Navigation
import Authenticate
import LoggedIn
import API
import Routing exposing (..)
import Html exposing (..)
import Html.App as App


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
        ( loggedIn, loggedInMsgs ) =
            LoggedIn.init

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
        ( { authenticate = authenticate, loggedIn = loggedIn, route = currentRoute, token = token }
        , Cmd.batch
            [ Cmd.map LoggedIn loggedInMsgs
            , Cmd.map Authenticate authenticateMsgs
            ]
        )



-- url`


urlUpdate : Result String Route -> Model -> ( Model, Cmd Msg )
urlUpdate result model =
    let
        currentRoute =
            Routing.routeFromResult result

        authenticated =
            case model.authenticate.activeUser of
                Just user ->
                    True

                Nothing ->
                    False

        newRoute =
            if authenticated then
                case currentRoute of
                    SignupRoute ->
                        HomeRoute

                    LoginRoute ->
                        HomeRoute

                    _ ->
                        currentRoute
            else
                case currentRoute of
                    HomeRoute ->
                        LoginRoute

                    _ ->
                        currentRoute

        commands =
            if newRoute == currentRoute then
                Cmd.none
            else
                (Routing.updateUrl newRoute)
    in
        ( { model | route = newRoute }, commands )



-- MODEL


type alias Model =
    { authenticate : Authenticate.Model
    , loggedIn : LoggedIn.Model
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
    = LoggedIn LoggedIn.Msg
    | Authenticate Authenticate.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoggedIn subMsg ->
            case subMsg of
                LoggedIn.Logout ->
                    ( { model
                        | loggedIn = LoggedIn.emptyModel
                        , authenticate = Authenticate.emptyModel
                        , route = LoginRoute
                      }
                    , Cmd.batch
                        [ Authenticate.setToken Nothing
                        , Routing.updateUrl HomeRoute
                        ]
                    )

                _ ->
                    let
                        ( loggedIn, loggedInCmds ) =
                            LoggedIn.update subMsg model.loggedIn
                    in
                        ( { model | loggedIn = loggedIn }
                        , Cmd.map LoggedIn loggedInCmds
                        )

        Authenticate subMsg ->
            let
                ( authenticate, authenticateCmds ) =
                    Authenticate.update subMsg model.authenticate

                newCreds =
                    case authenticate.activeUser of
                        Just creds ->
                            True

                        Nothing ->
                            False

                cmds =
                    if newCreds then
                        Cmd.batch
                            [ Cmd.map Authenticate authenticateCmds
                            , Routing.updateUrl HomeRoute
                            ]
                    else
                        Cmd.map Authenticate authenticateCmds
            in
                ( { model | authenticate = authenticate }
                , cmds
                )



-- VIEW


view : Model -> Html Msg
view model =
    case model.route of
        LoginRoute ->
            App.map
                (\msg -> Authenticate msg)
                (Authenticate.view model.authenticate Authenticate.LoginView)

        SignupRoute ->
            App.map
                (\msg -> Authenticate msg)
                (Authenticate.view model.authenticate Authenticate.SignupView)

        HomeRoute ->
            App.map
                (\msg -> LoggedIn msg)
                (LoggedIn.view model.loggedIn)

        NotFoundRoute ->
            div [] [ text "NOT FOUND" ]

module Authenticate exposing (..)

import Signup
import Html exposing (..)
import Html.App as App


main : Program ActiveUserCreds
main =
    App.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { signup : Signup.Model
    , activeUser : ActiveUserCreds
    }


type alias ActiveUserCreds =
    { token : Maybe String
    , email : Maybe String
    }


init : ActiveUserCreds -> ( Model, Cmd Msg )
init creds =
    let
        ( signupModel, signupMsgs ) =
            Signup.init
    in
        ( { signup = signupModel
          , activeUser = creds
          }
        , Cmd.batch
            [ Cmd.map Signup signupMsgs ]
        )


type Msg
    = Signup Signup.Msg
    | Logout


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Signup subMsg ->
            let
                ( signup, signupCmds ) =
                    Signup.update subMsg model.signup
            in
                ( { model | signup = signup }
                , Cmd.map Signup signupCmds
                )

        Logout ->
            ( { model | activeUser = ActiveUserCreds Nothing Nothing }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    let
        tokenText =
            case model.activeUser.token of
                Just token ->
                    token

                Nothing ->
                    "nothing here"
    in
        div []
            [ App.map Signup (Signup.view model.signup)
            , text tokenText
            ]



--


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

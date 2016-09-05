module LoggedIn exposing (..)

import StopsList exposing (..)
import Html exposing (Html, div, button, text)
import Html.App as App
import Html.Events exposing (onClick)
import Authenticate


type alias Model =
    { stopsList : StopsList.Model
    }


emptyModel : Model
emptyModel =
    { stopsList = StopsList.initialModel }


init : ( Model, Cmd Msg )
init =
    let
        ( stopsList, stopsListMessages ) =
            StopsList.init
    in
        ( { stopsList = stopsList
          }
        , Cmd.map StopsList stopsListMessages
        )


type Msg
    = StopsList StopsList.Msg
    | Logout


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        StopsList subMessage ->
            let
                ( stopsList, stopsListMessages ) =
                    StopsList.update subMessage model.stopsList
            in
                ( { model | stopsList = stopsList }
                , Cmd.map StopsList stopsListMessages
                )

        Logout ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ App.map StopsList (StopsList.view model.stopsList)
            ]
        , div []
            [ button [ onClick Logout ] [ text "Logout!" ]
            ]
        ]

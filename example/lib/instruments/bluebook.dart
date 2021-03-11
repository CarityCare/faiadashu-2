class BluebookInstrument {
  static const bluebookInstrument = '''
  {
  "resourceType": "Questionnaire",
  "id": "bb",
  "url": "http://hl7.org/fhir/Questionnaire/bb",
  "title": "NSW Government My Personal Health Record",
  "status": "draft",
  "subjectType": [
    "Patient"
  ],
  "date": "2013-02-19",
  "publisher": "New South Wales Department of Health",
  "jurisdiction": [
    {
      "coding": [
        {
          "system": "urn:iso:std:iso:3166",
          "code": "AU"
        }
      ]
    }
  ],
  "item": [
    {
      "linkId": "birthDetails",
      "text": "Birth details - To be completed by health professional",
      "type": "group",
      "item": [
        {
          "linkId": "group",
          "type": "group",
          "item": [
            {
              "linkId": "nameOfChild",
              "text": "Name of child",
              "type": "string"
            },
            {
              "linkId": "sex",
              "text": "Sex",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "code": "F"
                  }
                },
                {
                  "valueCoding": {
                    "code": "M"
                  }
                }
              ]
            }
          ]
        },
        {
          "linkId": "neonatalInformation",
          "text": "Neonatal Information",
          "type": "group",
          "item": [
            {
              "linkId": "birthWeight",
              "text": "Birth weight (kg)",
              "type": "decimal"
            },
            {
              "linkId": "birthLength",
              "text": "Birth length (cm)",
              "type": "decimal"
            },
            {
              "linkId": "vitaminKgiven",
              "text": "Vitamin K given",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "code": "INJECTION"
                  }
                },
                {
                  "valueCoding": {
                    "code": "INTRAVENOUS"
                  }
                },
                {
                  "valueCoding": {
                    "code": "ORAL"
                  }
                }
              ],
              "item": [
                {
                  "linkId": "vitaminKgivenDoses",
                  "type": "group",
                  "enableWhen": [
                    {
                      "question": "vitaminKgiven",
                      "operator": "exists",
                      "answerBoolean": true
                    }
                  ],
                  "item": [
                    {
                      "linkId": "vitaminiKDose1",
                      "text": "1st dose",
                      "type": "dateTime"
                    },
                    {
                      "linkId": "vitaminiKDose2",
                      "text": "2nd dose",
                      "type": "dateTime"
                    }
                  ]
                }
              ]
            },
            {
              "linkId": "hepBgiven",
              "text": "Hep B given y / n",
              "type": "boolean",
              "item": [
                {
                  "linkId": "hepBgivenDate",
                  "text": "Date given",
                  "type": "date"
                }
              ]
            },
            {
              "linkId": "abnormalitiesAtBirth",
              "text": "Abnormalities noted at birth",
              "type": "string"
            }
          ]
        }
      ]
    }
  ]
}
''';
}

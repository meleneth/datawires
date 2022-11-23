import { expect } from 'chai'

import Builder from '@/components/DataView/builder.coffee'
import DecoratedFormBuilder from '@/lib/decorated/form.coffee'

describe 'DecoratedFormBuilder', =>
  describe "#add_textarea", =>
    it 'works for simple case', =>
      builder = new DecoratedFormBuilder
      builder.add_textarea "About", "Write a few sentances about yourself", {some_field: "blah"}, 'some_field'
      uid = builder.data.children[0].children[0].children[0].for
      expect(builder.data).to.eql
        "children": [
          {
            "children": [
              {
                "children": [
                  {
                    "children": [
                      {
                        "classes": {}
                        "style": {}
                        "text": "About"
                        "type": "text"
                      }
                    ]
                    "classes": {}
                    "for": uid
                    "style": {}
                    "text": ""
                    "type": "form"
                  }
                  {
                    "children": [
                      {
                        "children": []
                        "classes": {
                          "block": true
                          "border-gray-300": true
                          "rounded-md": true
                          "shadow-sm": true
                          "w-full": true
                        }
                        "field": "some_field"
                        "id": uid
                        "name": uid
                        "style": {}
                        "target": {
                          "some_field": "blah"
                        }
                        "type": "textarea"
                      }
                    ]
                    "classes": {
                      "mt-1": true
                    }
                    "style": {}
                    "type": "div"
                  }
                  {
                    "children": [
                      {
                        "classes": {}
                        "style": {}
                        "text": "Write a few sentances about yourself"
                        "type": "text"
                      }
                    ]
                    "classes": {
                      "mt-2": true
                      "text-gray-500": true
                      "text-sm": true
                    }
                    "style": {}
                    "type": "p"
                  }
                ]
                "classes": {
                  "sm:col-span-6": true
                }
                "style": {}
                "type": "div"
              }
            ]
            "classes": {
              "divide-gray-200": true
              "divide-y": true
              "space-y-8": true
            }
            "style": {}
            "type": "div"
          }
        ]
        "classes": {
          "divide-gray-200": true
          "divide-y": true
          "space-y-8": true
        }
        "style": {}
        "type": "form"
  describe "#add_input", =>
    it "works for a simple case", =>
      info = {first_name: "good", last_name: "bad"}
      builder = new Builder 'div'
      dfbuilder = new DecoratedFormBuilder
      dfbuilder.add_input builder, "First Name", info, 'first_name'
      uid = builder.data.children[0].for
      expect(builder.data).to.eql
        "children": [
          {
            "children": [
              {
                "classes": {}
                "style": {}
                "text": "First Name"
                "type": "text"
              }
            ]
            "classes": {
              "block": true
              "font-medium": true
              "text-gray-700": true
              "text-sm": true
            }
            "for": uid
            "style": {}
            "text": ""
            "type": "form"
          }
          {
            "children": [
              {
                "children": []
                "classes": {
                  "block": true
                  "border-gray-300": true
                  "focus:border-indigo-500": true
                  "focus:ring-indigo-500": true
                  "rounded-md": true
                  "shadow-sm": true
                  "sm:text-sm": true
                  "w-full": true
                }
                "field": "first_name"
                "id": uid
                "input_type": "text"
                "style": {}
                "target": {
                  "first_name": "good"
                  "last_name": "bad"
                }
                "type": "input"
              }
            ]
            "classes": {
              "mt-1": true
            }
            "style": {}
            "type": "div"
          }
        ]
        "classes": {}
        "style": {}
        "type": "div"

  describe "#add_line_2", =>
    it 'works for simple case', =>
      builder = new DecoratedFormBuilder
      line = builder.add_line_2()
      expected =
        "children": []
        "classes": {
          "sm:col-span-3": true
        }
        "style": {}
        "type": "div"
      expect(line[0].data).to.eql expected
      expect(line[1].data).to.eql expected
    it 'works for input case', =>
      builder = new DecoratedFormBuilder
      line = builder.add_line_2()
      info = {first_name: "good", last_name: "bad"}

      builder.add_input line[0], "First name", info, 'first_name'
      builder.add_input line[1], "Last name", info, 'last_name'
      observed = builder.data
      uid1 = builder.data.children[1].children[0].children[0].for
      uid2 = builder.data.children[1].children[1].children[0].for
      expected =
        "children": [
          {
            "children": []
            "classes": {
              "divide-gray-200": true
              "divide-y": true
              "space-y-8": true
            }
            "style": {}
            "type": "div"
          }
          {
            "children": [
              {
                "children": [
                  {
                    "children": [
                      {
                        "classes": {}
                        "style": {}
                        "text": "First name"
                        "type": "text"
                      }
                    ]
                    "classes": {
                      "block": true
                      "font-medium": true
                      "text-gray-700": true
                      "text-sm": true
                    }
                    "for": uid1
                    "style": {}
                    "text": ""
                    "type": "form"
                  }
                  {
                    "children": [
                      {
                        "children": []
                        "classes": {
                          "block": true
                          "border-gray-300": true
                          "focus:border-indigo-500": true
                          "focus:ring-indigo-500": true
                          "rounded-md": true
                          "shadow-sm": true
                          "sm:text-sm": true
                          "w-full": true
                        }
                        "field": "first_name"
                        "id": uid1
                        "input_type": "text"
                        "style": {}
                        "target": {
                          "first_name": "good"
                          "last_name": "bad"
                        }
                        "type": "input"
                      }
                    ]
                    "classes": {
                      "mt-1": true
                    }
                    "style": {}
                    "type": "div"
                  }
                ]
                "classes": {
                  "sm:col-span-3": true
                }
                "style": {}
                "type": "div"
              }
              {
                "children": [
                  {
                    "children": [
                      {
                        "classes": {}
                        "style": {}
                        "text": "Last name"
                        "type": "text"
                      }
                    ]
                    "classes": {
                      "block": true
                      "font-medium": true
                      "text-gray-700": true
                      "text-sm": true
                    }
                    "for": uid2
                    "style": {}
                    "text": ""
                    "type": "form"
                  }
                  {
                    "children": [
                      {
                        "children": []
                        "classes": {
                          "block": true
                          "border-gray-300": true
                          "focus:border-indigo-500": true
                          "focus:ring-indigo-500": true
                          "rounded-md": true
                          "shadow-sm": true
                          "sm:text-sm": true
                          "w-full": true
                        }
                        "field": "last_name"
                        "id": uid2
                        "input_type": "text"
                        "style": {}
                        "target": {
                          "first_name": "good"
                          "last_name": "bad"
                        }
                        "type": "input"
                      }
                    ]
                    "classes": {
                      "mt-1": true
                    }
                    "style": {}
                    "type": "div"
                  }
                ]
                "classes": {
                  "sm:col-span-3": true
                }
                "style": {}
                "type": "div"
              }
            ]
            "classes": {
              "gap-x-4": true
              "gap-y-6": true
              "grid": true
              "grid-cols-1": true
              "mt-6": true
              "sm:grid-cols-6": true
            }
            "style": {}
            "type": "div"
          }
        ]
        "classes": {
          "divide-gray-200": true
          "divide-y": true
          "space-y-8": true
        }
        "style": {}
        "type": "form"
      expect(observed).to.eql expected


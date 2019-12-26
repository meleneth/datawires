import { expect } from 'chai'
import { shallowMount } from '@vue/test-utils'
import VueMogrifier from '@/VueMogrifier.coffee'

describe 'VueMogrifier.vue', =>
  describe '#couch2vue', =>
    it "removes unsafe keys", =>
      doc =
        _id: "91fcda45-9a63-4d26-9a59-e8bd68d75317"
        _rev: "6-62f1dc34ca219fa5609e59030c554f3e"
        $ref: "http://example.org"
        name: "flowers"
      result = VueMogrifier.couch2vue(doc)
      expect(result.id).to.include("91fcda45-9a63-4d26-9a59-e8bd68d75317")
      expect(result.rev).to.include("6-62f1dc34ca219fa5609e59030c554f3e")
      expect(result.attributes.ref).to.include("http://example.org")
      expect(result.doc.name).to.include("flowers")

  describe '#vue2couch', =>
    it "reassembles unsafe keys", =>
      doc =
        id: "91fcda45-9a63-4d26-9a59-e8bd68d75317"
        rev: "6-62f1dc34ca219fa5609e59030c554f3e"
        attributes:
          ref: "http://example.org"
        doc:
          name: "flowers"
      result = VueMogrifier.vue2couch(doc)
      expect(result.name).to.include("flowers")
      expect(result.$ref).to.include("http://example.org")
      expect(result._rev).to.include("6-62f1dc34ca219fa5609e59030c554f3e")
      expect(result._id).to.include("91fcda45-9a63-4d26-9a59-e8bd68d75317")


const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Category name is required'],
    unique: true,
    trim: true,
    maxlength: [50, 'Category name cannot exceed 50 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Category description cannot exceed 500 characters']
  },
  slug: {
    type: String,
    unique: true,
    lowercase: true,
    trim: true
  },
  parent: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    default: null
  },
  level: {
    type: Number,
    default: 0,
    min: [0, 'Level cannot be negative']
  },
  path: {
    type: String,
    default: ''
  },
  image: {
    url: String,
    alt: String
  },
  icon: {
    type: String,
    default: 'folder'
  },
  color: {
    type: String,
    default: '#6B7280',
    match: [/^#[0-9A-F]{6}$/i, 'Color must be a valid hex color']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isFeatured: {
    type: Boolean,
    default: false
  },
  sortOrder: {
    type: Number,
    default: 0
  },
  seoTitle: {
    type: String,
    maxlength: [60, 'SEO title cannot exceed 60 characters']
  },
  seoDescription: {
    type: String,
    maxlength: [160, 'SEO description cannot exceed 160 characters']
  },
  seoKeywords: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  productCount: {
    type: Number,
    default: 0,
    min: [0, 'Product count cannot be negative']
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for children categories
categorySchema.virtual('children', {
  ref: 'Category',
  localField: '_id',
  foreignField: 'parent'
});

// Virtual for full path
categorySchema.virtual('fullPath').get(function() {
  return this.path ? `${this.path} > ${this.name}` : this.name;
});

// Indexes for performance
categorySchema.index({ name: 1 });
categorySchema.index({ slug: 1 });
categorySchema.index({ parent: 1 });
categorySchema.index({ isActive: 1 });
categorySchema.index({ isFeatured: 1 });
categorySchema.index({ sortOrder: 1 });
categorySchema.index({ level: 1 });

// Pre-save middleware to generate slug
categorySchema.pre('save', function(next) {
  if (this.isModified('name') && !this.slug) {
    this.slug = this.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');
  }
  next();
});

// Pre-save middleware to set level and path
categorySchema.pre('save', async function(next) {
  if (this.isModified('parent')) {
    if (this.parent) {
      const parentCategory = await this.constructor.findById(this.parent);
      if (parentCategory) {
        this.level = parentCategory.level + 1;
        this.path = parentCategory.path ? `${parentCategory.path} > ${parentCategory.name}` : parentCategory.name;
      }
    } else {
      this.level = 0;
      this.path = '';
    }
  }
  next();
});

// Post-save middleware to update product count
categorySchema.post('save', async function() {
  if (this.isModified('isActive')) {
    await this.constructor.updateProductCount(this._id);
  }
});

// Method to get all descendants
categorySchema.methods.getDescendants = async function() {
  const descendants = [];
  
  const getChildren = async (categoryId) => {
    const children = await this.constructor.find({ parent: categoryId, isActive: true });
    for (const child of children) {
      descendants.push(child);
      await getChildren(child._id);
    }
  };
  
  await getChildren(this._id);
  return descendants;
};

// Method to get all ancestors
categorySchema.methods.getAncestors = async function() {
  const ancestors = [];
  let current = this;
  
  while (current.parent) {
    current = await this.constructor.findById(current.parent);
    if (current) {
      ancestors.unshift(current);
    } else {
      break;
    }
  }
  
  return ancestors;
};

// Static method to get category tree
categorySchema.statics.getTree = function() {
  return this.find({ isActive: true })
    .sort({ sortOrder: 1, name: 1 })
    .populate('parent', 'name slug')
    .lean();
};

// Static method to get featured categories
categorySchema.statics.getFeatured = function(limit = 10) {
  return this.find({ isActive: true, isFeatured: true })
    .sort({ sortOrder: 1, name: 1 })
    .limit(limit);
};

// Static method to update product count
categorySchema.statics.updateProductCount = async function(categoryId) {
  const Product = mongoose.model('Product');
  const count = await Product.countDocuments({ 
    category: categoryId, 
    isActive: true 
  });
  
  await this.findByIdAndUpdate(categoryId, { productCount: count });
  
  // Update parent categories
  const category = await this.findById(categoryId);
  if (category && category.parent) {
    await this.updateProductCount(category.parent);
  }
};

// Static method to get category breadcrumb
categorySchema.statics.getBreadcrumb = async function(categoryId) {
  const category = await this.findById(categoryId);
  if (!category) return [];
  
  const breadcrumb = await category.getAncestors();
  breadcrumb.push(category);
  
  return breadcrumb;
};

// Static method to validate category hierarchy
categorySchema.statics.validateHierarchy = async function(categoryId, parentId) {
  if (!parentId) return true;
  
  if (categoryId.toString() === parentId.toString()) {
    throw new Error('Category cannot be its own parent');
  }
  
  const parent = await this.findById(parentId);
  if (!parent) {
    throw new Error('Parent category not found');
  }
  
  // Check if parent is not a descendant of current category
  const descendants = await this.find({ parent: categoryId });
  for (const descendant of descendants) {
    if (descendant._id.toString() === parentId.toString()) {
      throw new Error('Category cannot be parent of its own descendant');
    }
  }
  
  return true;
};

module.exports = mongoose.model('Category', categorySchema);
